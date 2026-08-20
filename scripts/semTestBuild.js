require('dotenv').config({ quiet: true });
let cookieJar = "";

function parseTemplateIds(value) {
    return String(value || "")
        .split(',')
        .map(id => Number(id.trim()))
        .filter(Number.isInteger);
}

const configED = {
    winDesc: process.env.WINTESTDESC,
    linuxDesc: process.env.LINUXTESTDESC,
    winTemp: parseTemplateIds(process.env.WINTESTTEMPLATES),
    linuxTemp: parseTemplateIds(process.env.LINUXTESTTEMPLATES)
};

const configAPI = {
    baseURL: process.env.BASEURL,
    username: process.env.SEMUSER,
    password: process.env.SEMPWD,
    projectID: process.env.PROJECTID
};

async function login() {
    try {
        const response = await fetch(`${configAPI.baseURL}/auth/login`, {
            method: "POST",
            body: JSON.stringify({
                auth: configAPI.username,
                password: configAPI.password
            }),
            headers: {
                "Content-type": "application/json"
            }
        });
        if (!response.ok) {
            throw new Error(`Login Response: ${response.status}`);
        }
        console.log("Login successful");
        cookieJar = response.headers.get("set-cookie");
    } catch (error) {
        console.error(`Login Error: ${error.message}`);
    }
}

async function fetchTemplate(templateId) {
    const response = await fetch(`${configAPI.baseURL}/project/${configAPI.projectID}/templates/${templateId}`, {
        headers: {
            Cookie: cookieJar
        }
    });

    if (!response.ok) {
        throw new Error(`Fetch Template ${templateId} Response: ${response.status}`);
    }

    return response.json();
}

function buildFallbackPayload(template, description) {
    const allowedKeys = [
        "id",
        "name",
        "project_id",
        "inventory_id",
        "repository_id",
        "environment_id",
        "view_id",
        "vault_id",
        "app",
        "playbook",
        "description",
        "arguments",
        "task_params",
        "survey_vars",
        "suppress_success_alerts",
        "allow_override_args",
        "build_template_id",
        "start_version",
        "git_branch",
        "type"
    ];

    const payload = {};
    for (const key of allowedKeys) {
        if (Object.hasOwn(template, key)) {
            payload[key] = template[key];
        }
    }
    payload.description = description;
    return payload;
}

async function updateDescription(templateId, description) {
    const template = await fetchTemplate(templateId);

    if (template.description === description) {
        console.log(`Template ${templateId} unchanged`);
        return;
    }

    const payload = { ...template, description };
    delete payload.last_task;
    delete payload.author;
    delete payload.created;
    delete payload.updated;

    let response = await fetch(`${configAPI.baseURL}/project/${configAPI.projectID}/templates/${templateId}`, {
        method: "PUT",
        body: JSON.stringify(payload),
        headers: {
            "Content-type": "application/json",
            Cookie: cookieJar
        }
    });

    if (!response.ok) {
        const fallbackPayload = buildFallbackPayload(template, description);
        response = await fetch(`${configAPI.baseURL}/project/${configAPI.projectID}/templates/${templateId}`, {
            method: "PUT",
            body: JSON.stringify(fallbackPayload),
            headers: {
                "Content-type": "application/json",
                Cookie: cookieJar
            }
        });
    }

    if (!response.ok) {
        throw new Error(`Update Template ${templateId} Response: ${response.status}`);
    }

    console.log(`Template ${templateId} description updated`);
}

async function updateTemplateGroup(templateIds, description) {
    for (const templateId of templateIds) {
        try {
            await updateDescription(templateId, description);
        } catch (error) {
            console.error(`Template ${templateId} Error: ${error.message}`);
        }
    }
}

async function logout() {
    try {
        const response = await fetch(`${configAPI.baseURL}/auth/logout`, {
            method: "POST",
            headers: {
                Cookie: cookieJar
            }
        });
        if (!response.ok) {
            throw new Error(`Logout Response: ${response.status}`);
        } 
        console.log("Logout successful");
    } catch (error) {
        console.error(`Logout Error: ${error.message}`);
    }
}

async function run() {
    await login();
    await updateTemplateGroup(configED.winTemp, configED.winDesc);
    await updateTemplateGroup(configED.linuxTemp, configED.linuxDesc);
    await logout();
}

run();