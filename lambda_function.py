import json
import logging
import os
import boto3
from botocore.exceptions import ClientError, BotoCoreError
import time
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize Bedrock client
bedrock_client = boto3.client(
    service_name='bedrock-runtime',
    region_name=os.environ.get('AWS_REGION', 'us-east-1')
)

# Get model configuration from environment variables
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
MAX_TOKENS = int(os.environ.get('MAX_TOKENS', '1000'))
TEMPERATURE = float(os.environ.get('TEMPERATURE', '0.7'))
TOP_P = float(os.environ.get('TOP_P', '0.9'))

def create_response(status_code: int, body: Dict[str, Any], headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    """Create a standardized API Gateway response"""
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
    """Validate the incoming request"""
    try:
        # Handle OPTIONS request for CORS
        if event.get('httpMethod') == 'OPTIONS':
            return True, "CORS preflight", None
        
        # Check if it's a POST request
        if event.get('httpMethod') != 'POST':
            return False, "Only POST method is supported", None
        
        # Parse request body
        if 'body' not in event or not event['body']:
            return False, "Request body is required", None
        
        body = json.loads(event['body'])
        
        # Validate required fields
        if 'prompt' not in body or not body['prompt']:
            return False, "Prompt is required in request body", None
        
        # Validate optional fields
        if 'max_tokens' in body and (not isinstance(body['max_tokens'], int) or body['max_tokens'] < 1):
            return False, "max_tokens must be a positive integer", None
        
        if 'temperature' in body and (not isinstance(body['temperature'], (int, float)) or not 0 <= body['temperature'] <= 1):
            return False, "temperature must be a number between 0 and 1", None
        
        if 'top_p' in body and (not isinstance(body['top_p'], (int, float)) or not 0 <= body['top_p'] <= 1):
            return False, "top_p must be a number between 0 and 1", None
        
        return True, "Valid request", body
        
    except json.JSONDecodeError:
        return False, "Invalid JSON in request body", None
    except Exception as e:
        logger.error(f"Error validating request: {str(e)}")
        return False, "Internal validation error", None

def invoke_bedrock_model(prompt: str, max_tokens: int = None, temperature: float = None, top_p: float = None) -> Dict[str, Any]:
    """Invoke Amazon Bedrock model"""
    try:
        # Use provided parameters or defaults
        max_tokens = max_tokens or MAX_TOKENS
        temperature = temperature or TEMPERATURE
        top_p = top_p or TOP_P
        
        # Prepare request body based on model
        if 'anthropic' in BEDROCK_MODEL_ID:
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": max_tokens,
                "temperature": temperature,
                "top_p": top_p,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
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
            # Generic format for other models
            request_body = {
                "prompt": prompt,
                "max_tokens": max_tokens,
                "temperature": temperature,
                "top_p": top_p
            }
        
        logger.info(f"Invoking Bedrock model: {BEDROCK_MODEL_ID}")
        logger.debug(f"Request body: {json.dumps(request_body, indent=2)}")
        
        # Invoke the model
        response = bedrock_client.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body)
        )
        
        # Parse response based on model
        response_body = json.loads(response['body'].read())
        
        if 'anthropic' in BEDROCK_MODEL_ID:
            content = response_body['content'][0]['text']
        elif 'amazon.titan' in BEDROCK_MODEL_ID:
            content = response_body['results'][0]['outputText']
        else:
            # Generic response parsing
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
        logger.error(f"Bedrock ClientError: {error_code} - {error_message}")
        return {
            'success': False,
            'error': {
                'code': error_code,
                'message': error_message
            }
        }
    except BotoCoreError as e:
        logger.error(f"Bedrock BotoCoreError: {str(e)}")
        return {
            'success': False,
            'error': {
                'code': 'BotoCoreError',
                'message': str(e)
            }
        }
    except Exception as e:
        logger.error(f"Unexpected error invoking Bedrock: {str(e)}")
        return {
            'success': False,
            'error': {
                'code': 'InternalError',
                'message': 'An unexpected error occurred'
            }
        }

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Main Lambda handler function"""
    start_time = time.time()
    
    try:
        logger.info(f"Received event: {json.dumps(event, indent=2)}")
        
        # Validate request
        is_valid, message, request_body = validate_request(event)
        
        if not is_valid:
            return create_response(400, {
                'error': True,
                'message': message,
                'timestamp': int(time.time())
            })
        
        # Handle CORS preflight
        if event.get('httpMethod') == 'OPTIONS':
            return create_response(200, {
                'message': 'CORS preflight successful',
                'timestamp': int(time.time())
            })
        
        # Extract parameters from request
        prompt = request_body['prompt']
        max_tokens = request_body.get('max_tokens')
        temperature = request_body.get('temperature')
        top_p = request_body.get('top_p')
        
        # Invoke Bedrock model
        result = invoke_bedrock_model(prompt, max_tokens, temperature, top_p)
        
        # Calculate execution time
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
            
            logger.info(f"Successfully processed request in {execution_time:.2f}s")
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
            
            logger.error(f"Failed to process request: {result['error']}")
            return create_response(500, response_body)
            
    except Exception as e:
        execution_time = time.time() - start_time
        logger.error(f"Unexpected error in handler: {str(e)}", exc_info=True)
        
        return create_response(500, {
            'success': False,
            'error': {
                'code': 'InternalServerError',
                'message': 'An unexpected error occurred'
            },
            'metadata': {
                'execution_time_ms': round(execution_time * 1000, 2),
                'timestamp': int(time.time()),
                'request_id': context.aws_request_id if context else None
            }
        }) 