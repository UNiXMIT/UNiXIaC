# Semaphore API
### Login
POST /api/auth/login  
```
{
  "auth": "email@domain.com",
  "password": "strongPassword123"
}
```

### Get Template
GET /api/project/{project_id}/templates/{template_id}  

### Create Template
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
``````

### Logout
POST /api/auth/logout  