require('dotenv').config({ quiet: true });
const dryRun = process.argv.includes("--dryrun");
let cookieJar = "";
const templateNumbers = process.env.TEMPLATENUMBERS
  .split(',')
  .map(n => Number(n.trim()));

const configED = {
    version: process.env.EDVERSION,
    get versionNumber() {
        return this.version.replace(".", "");
    },
    pu: process.env.EDPU,
    get puFormatted() {
        return this.pu.length === 1 ? "0" + this.pu : this.pu;
    },
    vsVersion: process.env.VSVERSION,
    winBuild: process.env.WINBUILD,
    linuxBuild: process.env.LINUXBUILD
};

const configACU = {
    majorVersion: process.env.ACUMAJORVERSION,
    pu: process.env.ACUPU,
    get version() {
        return this.majorVersion + '.' + this.pu;
    },
    get baseVersion() {
        return this.majorVersion.replace(".", "") + 0;
    },
    get versionNumber() {
        return this.majorVersion.replace(".", "") + this.pu;
    },
    company: process.env.COMPANY,
    companyMF: process.env.COMPANYMF,
    code86: process.env.CODE86,
    key86: process.env.KEY86,
    code64: process.env.CODE64,
    key64: process.env.KEY64,
    code: process.env.CODE,
    key: process.env.KEY
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
        for (const template of templateNumbers) {
            await fetchTemplates(template);
        }
    } catch (error) {
        console.error(`Login Error: ${error.message}`);
    }
}

async function fetchTemplates(templateNumber) {
    try {
        const response = await fetch(`${configAPI.baseURL}/project/${configAPI.projectID}/templates/${templateNumber}`, {
            headers: {
                Cookie: cookieJar
            }
        });
        if (!response.ok) {
            throw new Error(`Fetch Template Response: ${response.status}`);
        }
        const data = await response.json();
        await createTemplates(data);
    } catch (error) {
        console.error(`Fetch Template Error: ${error.message}`);
    }
}

const newValuesED = {
    productName: `ED${configED.versionNumber}PU${configED.pu}`,
    productNameES: `ES${configED.versionNumber}PU${configED.pu}`,
    installerNameEDVS: `edvs${configED.vsVersion}_${configED.versionNumber}.exe`,
    // installerNameEDnoVS: `edvs_${configED.versionNumber}.exe`,
    installerNameEDE: `ede_${configED.versionNumber}.exe`,
    installerNameES: `es_${configED.versionNumber}.exe`,
    S3Prefix: `ED/${configED.versionNumber}/GA/`,
    S3PrefixPU: `ED/${configED.versionNumber}/PU${configED.pu}/`,
    installPath: `/home/products/ed${configED.versionNumber}pu${configED.pu}`,
    installerNameEDVSPU: `edvs${configED.vsVersion}_${configED.versionNumber}_pu${configED.puFormatted}_${configED.winBuild}.exe`,
    installerNameEDnoVSPU: `edvs_${configED.versionNumber}_pu${configED.puFormatted}_${configED.winBuild}.exe`,
    installerNameEDEPU: `ede_${configED.versionNumber}_pu${configED.puFormatted}_${configED.winBuild}.exe`,
    installerNameESPU: `es_${configED.versionNumber}_pu${configED.puFormatted}_${configED.winBuild}.exe`,
    installerNameRHEL: `setup_entdev_${configED.version}_patchupdate${configED.puFormatted}_${configED.linuxBuild}_redhat_x86_64`,
    installerNameRHEL64: `setup_entdev_${configED.version}_patchupdate${configED.puFormatted}_${configED.linuxBuild}_redhat_x64`,
    installerNameRHELARM: `setup_entdev_${configED.version}_patchupdate${configED.puFormatted}_${configED.linuxBuild}_redhat_arm64`,
    installerNameSLES: `setup_entdev_${configED.version}_patchupdate${configED.puFormatted}_${configED.linuxBuild}_suse_x64`,
    installerNameUBUNTU: `setup_entdev_${configED.version}_patchupdate${configED.puFormatted}_${configED.linuxBuild}_ubuntu_x64`
};

const newValuesACU = {
    productName: `extend${configACU.versionNumber}`,
    installPath32: `C:\\Program Files (x86)\\${configACU.company}\\extend ${configACU.baseVersion}`,
    installPath64: `C:\\Program Files\\${configACU.company}\\extend ${configACU.baseVersion}`,
    installPath: `/home/products/acu${configACU.versionNumber}shx64/`,
    installerNameWIN: `extend(R) Version ${configACU.version} x64.msi`,
    installerNameLINUX: `setup_acucob${configACU.versionNumber}pmk31shACU`,
    S3Prefix: `AcuCOBOL/${configACU.baseVersion}/GA/`,
    S3PrefixPU: `AcuCOBOL/${configACU.baseVersion}/PU${configACU.pu}/`
};

const newValuesACUMF = {
    productName: `extend${configACU.majorVersion.replace(/\./g, "")}pu${configACU.pu}`,
    installPath32: `C:\\Program Files (x86)\\${configACU.companyMF}\\extend ${configACU.majorVersion}`,
    installPath64: `C:\\Program Files\\${configACU.companyMF}\\extend ${configACU.majorVersion}`,
    installPath: `/home/products/acu${configACU.majorVersion.replace(/\./g, "")}shx64pu${configACU.pu}/`,
    installerNameWIN: `extend(R) Version ${configACU.majorVersion} x64.msi`,
    installerNameLINUX: `setup_acucob${configACU.majorVersion.replace(/\./g, "")}pu${configACU.pu}pmk59shACU`,
    S3Prefix: `AcuCOBOL/${configACU.majorVersion.replace(/\./g, "")}/GA/`,
    S3PrefixPU: `AcuCOBOL/${configACU.majorVersion.replace(/\./g, "")}/PU${configACU.pu}/`
};

async function createTemplates(data) {
    data.arguments = JSON.stringify([]);
    let newArgs = [];

    const wins = data.task_params.tags.find(t => t.includes("wins"));
    if (wins) {
        if (data.task_params.tags.includes("ed")) {
            data.name = `${wins.toUpperCase()} - ED ${configED.version} PU ${configED.pu}`
            if ( (configED.versionNumber == 110 && configED.pu >= 5) || configED.versionNumber >= 120 ) {
                // newArgs.push(`-e installerNameEDVS=${newValuesED.installerNameEDnoVS}`);
                newArgs.push(`-e installerNameEDVSPU=${newValuesED.installerNameEDnoVSPU}`);
            } else {
                // newArgs.push(`-e installerNameEDVS=${newValuesED.installerNameEDVS}`);
                newArgs.push(`-e installerNameEDVSPU=${newValuesED.installerNameEDVSPU}`);
            }
            newArgs.push(`-e installerNameEDVS=${newValuesED.installerNameEDVS}`);
            newArgs.push(`-e installerNameEDE=${newValuesED.installerNameEDE}`);
            newArgs.push(`-e S3Prefix=${newValuesED.S3Prefix}`);
            newArgs.push(`-e productName=${newValuesED.productName}`);
            newArgs.push(`-e edVer=${configED.versionNumber}`);
            newArgs.push(`-e installerNameEDEPU=${newValuesED.installerNameEDEPU}`);
            newArgs.push(`-e S3PrefixPU=${newValuesED.S3PrefixPU}`);
        } else if (data.task_params.tags.includes("es")) {
            data.name = `${wins.toUpperCase()} - ES ${configED.version} PU ${configED.pu}`
            newArgs.push(`-e installerNameES=${newValuesED.installerNameES}`);
            newArgs.push(`-e S3Prefix=${newValuesED.S3Prefix}`);
            newArgs.push(`-e productName=${newValuesED.productNameES}`);
            newArgs.push(`-e edVer=${configED.versionNumber}`);
            newArgs.push(`-e installerNameESPU=${newValuesED.installerNameESPU}`);
            newArgs.push(`-e S3PrefixPU=${newValuesED.S3PrefixPU}`); 
        } else if (data.task_params.tags.includes("extend")) {
            if (configACU.versionNumber < 1100) {
                data.name = `${wins.toUpperCase()} - extend ${configACU.majorVersion} PU ${configACU.pu}`
                newArgs.push(`-e installPath32='${newValuesACUMF.installPath32}'`);
                newArgs.push(`-e installPath64='${newValuesACUMF.installPath64}'`);
                newArgs.push(`-e installerName='${newValuesACUMF.installerNameWIN}'`);
                newArgs.push(`-e S3Prefix=${newValuesACUMF.S3PrefixPU}`);
                newArgs.push(`-e productName=${newValuesACUMF.productName}`);
            } else {
                data.name = `${wins.toUpperCase()} - extend ${configACU.version}`
                newArgs.push(`-e installPath32='${newValuesACU.installPath32}'`);
                newArgs.push(`-e installPath64='${newValuesACU.installPath64}'`);
                newArgs.push(`-e installerName='${newValuesACU.installerNameWIN}'`);
                newArgs.push(`-e S3Prefix=${newValuesACU.S3PrefixPU}`);
                newArgs.push(`-e productName=${newValuesACU.productName}`);
            }
            newArgs.push(`-e CODE86=${configACU.code86}`);
            newArgs.push(`-e KEY86=${configACU.key86}`);
            newArgs.push(`-e CODE64=${configACU.code64}`);
            newArgs.push(`-e KEY64=${configACU.key64}`);
        }
    }

    const rhel = data.task_params.tags.find(t => t.includes("rhel"));
    if (rhel && data.task_params.tags.includes("ed")) {
        if (!data.task_params.tags.includes("arm")) {
            data.name = `${rhel.toUpperCase()} - ED ${configED.version} PU ${configED.pu}`
            if (configED.versionNumber >= 110) {
                newArgs.push(`-e installerName=${newValuesED.installerNameRHEL64}`);
            } else {
                newArgs.push(`-e installerName=${newValuesED.installerNameRHEL}`);
            }
            
        } else if (data.task_params.tags.includes("arm")) {
            data.name = `${rhel.toUpperCase()} ARM - ED ${configED.version} PU ${configED.pu}`
            newArgs.push(`-e installerName=${newValuesED.installerNameRHELARM}`);
        }
        newArgs.push(`-e productName=${newValuesED.productName}`);
        newArgs.push(`-e edVer=${configED.versionNumber}`);
        newArgs.push(`-e S3Prefix=${newValuesED.S3PrefixPU}`);
        newArgs.push(`-e installPath=${newValuesED.installPath}`);
    }

    const sles = data.task_params.tags.find(t => t.includes("sles"));
    if (sles && data.task_params.tags.includes("ed")) {
        data.name = `${sles.toUpperCase()} - ED ${configED.version} PU ${configED.pu}`
        newArgs.push(`-e productName=${newValuesED.productName}`);
        newArgs.push(`-e edVer=${configED.versionNumber}`);
        newArgs.push(`-e S3Prefix=${newValuesED.S3PrefixPU}`);
        newArgs.push(`-e installerName=${newValuesED.installerNameSLES}`);
        newArgs.push(`-e installPath=${newValuesED.installPath}`);
    }

    const ubuntu = data.task_params.tags.find(t => t.includes("ubuntu"));
    if (ubuntu && data.task_params.tags.includes("ed")) {
        if (ubuntu.includes("2404")) {
            data.name = `UBUNTU24.04 - ED ${configED.version} PU ${configED.pu}`
        } else if (ubuntu.includes("2204")) {
            data.name = `UBUNTU22.04 - ED ${configED.version} PU ${configED.pu}`
        }
        newArgs.push(`-e productName=${newValuesED.productName}`);
        newArgs.push(`-e edVer=${configED.versionNumber}`);
        newArgs.push(`-e S3Prefix=${newValuesED.S3PrefixPU}`);
        newArgs.push(`-e installerName=${newValuesED.installerNameUBUNTU}`);
        newArgs.push(`-e installPath=${newValuesED.installPath}`);
    }

    if ((rhel || sles || ubuntu) && data.task_params.tags.includes("extend")) {
        if (configACU.versionNumber < 1100) {
            if (rhel) {
                data.name = `${rhel.toUpperCase()} - extend ${configACU.majorVersion} PU ${configACU.pu}`
            } else if (sles) {
                data.name = `${sles.toUpperCase()} - extend ${configACU.majorVersion} PU ${configACU.pu}`
            } else if (ubuntu) {
                data.name = `${ubuntu.toUpperCase()} - extend ${configACU.majorVersion} PU ${configACU.pu}`
            }
            newArgs.push(`-e installPath=${newValuesACUMF.installPath}`);
            newArgs.push(`-e installerName=${newValuesACUMF.installerNameLINUX}`);
            newArgs.push(`-e S3Prefix=${newValuesACUMF.S3PrefixPU}`);
            newArgs.push(`-e productName=${newValuesACUMF.productName}`);
        } else {
            if (rhel) {
                data.name = `${rhel.toUpperCase()} - extend ${configACU.version}`
            } else if (sles) {
                data.name = `${sles.toUpperCase()} - extend ${configACU.version}`
            } else if (ubuntu) {
                data.name = `${ubuntu.toUpperCase()} - extend ${configACU.version}`
            }
            newArgs.push(`-e installPath=${newValuesACU.installPath}`);
            newArgs.push(`-e installerName=${newValuesACU.installerNameLINUX}`);
            newArgs.push(`-e S3Prefix=${newValuesACU.S3PrefixPU}`);
            newArgs.push(`-e productName=${newValuesACU.productName}`);
        }
        newArgs.push(`-e CODE=${configACU.code}`);
        newArgs.push(`-e KEY=${configACU.key}`);
    }

    data.arguments = JSON.stringify(newArgs);
    delete data.id;
    delete data.last_task;

    if (dryRun) {
        console.log(data);
    } else {
        try {
            const response = await fetch(`${configAPI.baseURL}/project/${configAPI.projectID}/templates`, {
                method: "POST",
                body: JSON.stringify(data),
                headers: {
                    "Content-type": "application/json",
                    Cookie: cookieJar
                }
            });
            if (!response.ok) {
                throw new Error(`Template Creation Response: ${response.status}`);
            }
            console.log(`Template creation successful: ${data.name}`);
        } catch (error) {
            console.error(`Template Creation Error: ${error.message}`);
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
    await logout();
}

run();