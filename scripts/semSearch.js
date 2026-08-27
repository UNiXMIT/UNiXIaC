require('dotenv').config({ quiet: true });

const configSearch = {
    searchString: process.env.SEARCHSTRING
};

const configAPI = {
    baseURL: process.env.BASEURL,
    apitoken: process.env.SEMTOKEN,
    projectID: process.env.PROJECTID
};

async function fetchTemplates() {
    const response = await fetch(`${configAPI.baseURL}/project/${configAPI.projectID}/templates`, {
        headers: {
            Authorization: `Bearer ${configAPI.apitoken}`
        }
    });

    if (!response.ok) {
        throw new Error(`Fetch Templates Response: ${response.status}`);
    }

    return response.json();
}

async function fetchTemplate(templateId) {
    const response = await fetch(`${configAPI.baseURL}/project/${configAPI.projectID}/templates/${templateId}`, {
        headers: {
            Authorization: `Bearer ${configAPI.apitoken}`
        }
    });

    if (!response.ok) {
        throw new Error(`Fetch Template ${templateId} Response: ${response.status}`);
    }

    return response.json();
}

async function searchTemplates() {
    if (!configSearch.searchString) {
        console.error("Search Error: SEARCHSTRING is not set in .env");
        return;
    }

    const matches = [];
    try {
        const templates = await fetchTemplates();
        for (const summary of templates) {
            try {
                const template = await fetchTemplate(summary.id);
                if (JSON.stringify(template).includes(configSearch.searchString)) {
                    matches.push(template.id);
                }
            } catch (error) {
                console.error(`Template ${summary.id} Error: ${error.message}`);
            }
        }
    } catch (error) {
        console.error(`Search Error: ${error.message}`);
        return;
    }

    if (matches.length) {
        console.log(`Templates matching "${configSearch.searchString}": ${matches.join(", ")}`);
    } else {
        console.log(`No templates matched "${configSearch.searchString}"`);
    }
}

async function run() {
    await searchTemplates();
}

run();
