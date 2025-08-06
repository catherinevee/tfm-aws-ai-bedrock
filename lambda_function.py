import json
import logging
import os
import boto3
from botocore.exceptions import ClientError, BotoCoreError
import time
from typing import Dict, Any, Optional

# Setup logging from environment variable
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize Bedrock client once at module level
bedrock_client = boto3.client(
    service_name='bedrock-runtime',
    region_name=os.environ.get('AWS_REGION', 'us-east-1')
)

# Model configuration from environment
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
MAX_TOKENS = int(os.environ.get('MAX_TOKENS', '1000'))
TEMPERATURE = float(os.environ.get('TEMPERATURE', '0.7'))
TOP_P = float(os.environ.get('TOP_P', '0.9'))

def create_response(status_code: int, body: Dict[str, Any], headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    """Standard API Gateway response with CORS headers"""
    default_headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
    }
    
    if headers:
        default_headers.update(headers)
    
    return {
        'statusCode': status_code,
        'headers': default_headers,
        'body': json.dumps(body, ensure_ascii=False)
    }

def validate_request(event: Dict[str, Any]) -> tuple[bool, str, Optional[Dict[str, Any]]]:
    """Validate incoming request and extract body"""
    try:
        # Handle CORS preflight requests
        if event.get('httpMethod') == 'OPTIONS':
            return True, "CORS preflight", None
        
        # Only accept POST requests
        if event.get('httpMethod') != 'POST':
            return False, "Only POST method supported", None
        
        # Parse request body
        if not event.get('body'):
            return False, "Request body required", None
        
        body = json.loads(event['body'])
        
        # Validate required fields
        if not body.get('prompt'):
            return False, "Prompt field required", None
        
        # Validate optional numeric parameters
        if 'max_tokens' in body and (not isinstance(body['max_tokens'], int) or body['max_tokens'] < 1):
            return False, "max_tokens must be positive integer", None
        
        if 'temperature' in body and not (0 <= body.get('temperature', 0) <= 1):
            return False, "temperature must be between 0 and 1", None
        
        if 'top_p' in body and not (0 <= body.get('top_p', 0) <= 1):
            return False, "top_p must be between 0 and 1", None
        
        return True, "Valid request", body
        
    except json.JSONDecodeError:
        return False, "Invalid JSON format", None
    except Exception as e:
        logger.error(f"Request validation error: {str(e)}")
        return False, "Validation failed", None

def invoke_bedrock_model(prompt: str, max_tokens: int = None, temperature: float = None, top_p: float = None) -> Dict[str, Any]:
    """Call Bedrock API with model-specific request formatting"""
    try:
        # Use provided parameters or environment defaults
        max_tokens = max_tokens or MAX_TOKENS
        temperature = temperature or TEMPERATURE
        top_p = top_p or TOP_P
        
        # Format request based on model family - each has different API expectations
        if 'anthropic' in BEDROCK_MODEL_ID:
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": max_tokens,
                "temperature": temperature,
                "top_p": top_p,
                "messages": [{"role": "user", "content": prompt}]
            }
        elif 'amazon.titan' in BEDROCK_MODEL_ID:
            request_body = {
                "inputText": prompt,
                "textGenerationConfig": {
                    "maxTokenCount": max_tokens,
                    "temperature": temperature,
                    "topP": top_p
                }
            }
        else:
            # Fallback format for other model families
            request_body = {
                "prompt": prompt,
                "max_tokens": max_tokens,
                "temperature": temperature,
                "top_p": top_p
            }
        
        logger.info(f"Calling Bedrock model: {BEDROCK_MODEL_ID}")
        
        response = bedrock_client.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body)
        )
        
        # Parse response based on model family
        response_body = json.loads(response['body'].read())
        
        if 'anthropic' in BEDROCK_MODEL_ID:
            content = response_body['content'][0]['text']
        elif 'amazon.titan' in BEDROCK_MODEL_ID:
            content = response_body['results'][0]['outputText']
        else:
            # Try common response fields
            content = response_body.get('completion', response_body.get('text', str(response_body)))
        
        return {
            'success': True,
            'content': content,
            'model_id': BEDROCK_MODEL_ID,
            'usage': response_body.get('usage', {}),
            'response_metadata': {
                'request_id': response.get('ResponseMetadata', {}).get('RequestId'),
                'model_id': BEDROCK_MODEL_ID
            }
        }
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        logger.error(f"Bedrock API error {error_code}: {error_message}")
        return {
            'success': False,
            'error': {'code': error_code, 'message': error_message}
        }
    except Exception as e:
        logger.error(f"Unexpected Bedrock call error: {str(e)}")
        return {
            'success': False,
            'error': {'code': 'InternalError', 'message': 'Bedrock API call failed'}
        }

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Main Lambda entry point - handles API Gateway requests"""
    start_time = time.time()
    
    try:
        logger.info(f"Processing request: {json.dumps(event, indent=2)}")
        
        # Validate request format and extract parameters
        is_valid, message, request_body = validate_request(event)
        
        if not is_valid:
            return create_response(400, {
                'error': True,
                'message': message,
                'timestamp': int(time.time())
            })
        
        # Handle CORS preflight - browsers send this before actual requests
        if event.get('httpMethod') == 'OPTIONS':
            return create_response(200, {
                'message': 'CORS preflight successful',
                'timestamp': int(time.time())
            })
        
        # Extract prompt and optional parameters
        prompt = request_body['prompt']
        max_tokens = request_body.get('max_tokens')
        temperature = request_body.get('temperature')
        top_p = request_body.get('top_p')
        
        # Call Bedrock API
        result = invoke_bedrock_model(prompt, max_tokens, temperature, top_p)
        
        execution_time = time.time() - start_time
        
        if result['success']:
            response_body = {
                'success': True,
                'content': result['content'],
                'model_id': result['model_id'],
                'usage': result['usage'],
                'metadata': {
                    'execution_time_ms': round(execution_time * 1000, 2),
                    'timestamp': int(time.time()),
                    'request_id': context.aws_request_id if context else None
                }
            }
            
            logger.info(f"Request completed in {execution_time:.2f}s")
            return create_response(200, response_body)
        else:
            response_body = {
                'success': False,
                'error': result['error'],
                'metadata': {
                    'execution_time_ms': round(execution_time * 1000, 2),
                    'timestamp': int(time.time()),
                    'request_id': context.aws_request_id if context else None
                }
            }
            
            logger.error(f"Request failed: {result['error']}")
            return create_response(500, response_body)
            
    except Exception as e:
        execution_time = time.time() - start_time
        logger.error(f"Handler error: {str(e)}", exc_info=True)
        
        return create_response(500, {
            'success': False,
            'error': {
                'code': 'InternalServerError',
                'message': 'Request processing failed'
            },
            'metadata': {
                'execution_time_ms': round(execution_time * 1000, 2),
                'timestamp': int(time.time()),
                'request_id': context.aws_request_id if context else None
            }
        }) 