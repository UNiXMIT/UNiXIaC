# Semaphore API
## Login
POST /api/auth/login  
```
{
  "auth": "email@example.com",
  "password": "strongPassword123"
}
```
cURL Example:  
```
curl --request POST \
  --url https://example.com/api/auth/login \
  --header 'Content-Type: application/json' \
  -c cookies.txt -b cookies.txt \
  --data '{
    "auth": "email@example.com",
    "password": "strongPassword123"
  }'
```

## Get Template
GET /api/project/{project_id}/templates/{template_id}  

cURL Example:  
```
curl --request GET \
  --url https://example.com/api/project/{project_id}/templates/{template_id} \
  -c cookies.txt -b cookies.txt
``` 

## Create Template
POST /api/project/{project_id}/templates  
```
{
  "project_id": 1,
  "inventory_id": 1,
  "repository_id": 1,
  "environment_id": 1,
  "view_id": 1,
  "name": "Test",
  "playbook": "test.yml",
  "arguments": "[]",
  "description": "Hello, World!",
  "allow_override_args_in_task": false,
  "limit": "",
  "suppress_success_alerts": true,
  "survey_vars": [
    {
      "name": "string",
      "title": "string",
      "description": "string",
      "type": "String => \"\", Integer => \"int\"",
      "required": true
    }
  ]
}
```
cURL Example:  
```
curl --request POST \
  --url https://example.com/api/project/{project_id}/templates \
  --header 'Content-Type: application/json' \
  -c cookies.txt -b cookies.txt \
  --data '{
    "project_id": 1,
    "inventory_id": 1,
    "repository_id": 1,
    "environment_id": 1,
    "view_id": 1,
    "name": "Test",
    "playbook": "test.yml",
    "arguments": "[]",
    "description": "Hello, World!",
    "allow_override_args_in_task": false,
    "limit": "",
    "suppress_success_alerts": true,
    "survey_vars": [
      {
        "name": "string",
        "title": "string",
        "description": "string",
        "type": "String => \"\", Integer => \"int\"",
        "required": true
      }
    ]
  }'
```
## Update Template  
PUT /project/{project_id}/templates/{template_id}
```
{
  "project_id": 1,
  "inventory_id": 1,
  "repository_id": 1,
  "environment_id": 1,
  "view_id": 1,
  "name": "Test",
  "playbook": "test.yml",
  "arguments": "[]",
  "description": "Hello, World!",
  "allow_override_args_in_task": false,
  "limit": "",
  "suppress_success_alerts": true,
  "survey_vars": [
    {
      "name": "string",
      "title": "string",
      "description": "string",
      "type": "String => \"\", Integer => \"int\"",
      "required": true
    }
  ]
}
```

cURL Example: 
```
curl --request PUT \
  --url https://example.com/api/project/{project_id}/templates/{template_id} \
  --header 'Content-Type: application/json' \
  -c cookies.txt -b cookies.txt \
  --data '{
    "project_id": 1,
    "inventory_id": 1,
    "repository_id": 1,
    "environment_id": 1,
    "view_id": 1,
    "name": "Test",
    "playbook": "test.yml",
    "arguments": "[]",
    "description": "Hello, World!",
    "allow_override_args_in_task": false,
    "limit": "",
    "suppress_success_alerts": true,
    "survey_vars": [
      {
        "name": "string",
        "title": "string",
        "description": "string",
        "type": "String => \"\", Integer => \"int\"",
        "required": true
      }
    ]
  }'
```

## Delete Task
DELETE /project/{project_id}/tasks/{task_id}

cURL Example:  
```
curl --request DELETE \
  --url https://example.com/project/{project_id}/tasks/{task_id} \
  -c cookies.txt -b cookies.txt
```

## Logout
POST /api/auth/logout  

cURL Example:  
```
curl --request POST \
  --url https://example.com/api/auth/logout \
  -c cookies.txt -b cookies.txt
```