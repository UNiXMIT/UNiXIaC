require('dotenv').config({ quiet: true });
const { Client: FtpClient } = require("basic-ftp");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const fs = require("node:fs");
const path = require("node:path");

const config = {
    ed: {
        version: process.env.EDVERSION,
        get versionNumber() {
            return this.version.replace(".", "");
        },
        pu: process.env.EDPU,
        get puFormatted() {
            return this.pu.length === 1 ? "0" + this.pu : this.pu;
        },
        get vsVersion() {
            if (this.versionNumber <= 100 || (this.versionNumber == 110 && this.pu <= 4)) {
                return "2022";
            }
            if ((this.versionNumber == 110 && this.pu >= 5) || this.versionNumber >= 120) {
                return "2026";
            }
        },
        winBuild: process.env.WINBUILD,
        linuxBuild: process.env.LINUXBUILD
    },
    acu: {
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
        }
    },
    ftp: {
        host: process.env.FTPHOST,
        user: process.env.FTPUSER,
        password: process.env.FTPPASS,
        secure: false,
    },
    s3: {
        region: process.env.AWSREGION,
        bucket: process.env.S3BUCKET,
    },
};

const ftpAccessOptions = {
    host: config.ftp.host,
    user: config.ftp.user,
    password: config.ftp.password,
    secure: config.ftp.secure,
};

const concurrency = {
    ftp: Number(process.env.FTPCONCURRENCY) || 5,
    s3: Number(process.env.S3CONCURRENCY) || 5,
};

const EDVars = {
    remoteDir: `${process.env.EDROOTLOC}/${config.ed.version}/patchupdates/pu${config.ed.puFormatted}`,
    get fileList() {
        const files = [
            `ede_${config.ed.versionNumber}_pu${config.ed.puFormatted}_${config.ed.winBuild}.exe`,
            `edvs_${config.ed.versionNumber}_pu${config.ed.puFormatted}_${config.ed.winBuild}.exe`,
            `es_${config.ed.versionNumber}_pu${config.ed.puFormatted}_${config.ed.winBuild}.exe`,
            `setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_amazon_x64`,
            `setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_suse_x64`,
            `setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_ubuntu_x64`
        ];
        if (config.ed.versionNumber == 100) {
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_redhat_x86_64`);
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_rocky_x86_64`);
        }
        if (config.ed.versionNumber == 110) {
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_redhat_x64`);
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_redhat_x86_64`);
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_rocky_x86_64`);
        }
        if (config.ed.versionNumber == 120) {
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_redhat_arm64`);
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_redhat_x64`);
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_redhat_x86_64`);
            files.push(`setup_entdev_${config.ed.version}_patchupdate${config.ed.puFormatted}_${config.ed.linuxBuild}_rocky_x64`);
        }
        return files;
    },
    localDir: `${process.env.EDLOCALLOC}\\${config.ed.versionNumber}\\PU${config.ed.puFormatted}`,
    S3Prefix: `${process.env.EDS3PREFIX}/${config.ed.versionNumber}/PU${config.ed.puFormatted}/`
}

const ACUVars = {
    remoteDir: `${process.env.ACUROOTLOC}/ACU${config.acu.versionNumber}/RCC`,
    get fileList() {
        const files = [];
        if (config.acu.versionNumber <= 1051) {
            files.push(`extend(R) Version ${config.acu.version} x64.msi`);
            files.push(`extend(R) Version ${config.acu.version} x86.msi`);
            files.push(`setup_acucob${config.acu.versionNumber}pu${config.acu.pu}pmk59shACU`);
            files.push(`setup_acucob${config.acu.versionNumber}pu${config.acu.pu}pmk59stACU`);
            files.push(`setup_acucob${config.acu.versionNumber}pu${config.acu.pu}pmk60shACU`);
            files.push(`setup_acucob${config.acu.versionNumber}pu${config.acu.pu}pmk60stACU`);
        }
        if (config.acu.versionNumber >= 1100 && config.acu.versionNumber < 1110) {
            files.push(`extend(R) Version ${config.acu.version} x64.msi`);
            files.push(`extend(R) Version ${config.acu.version} x86.msi`);
            files.push(`setup_acucob${config.acu.versionNumber}pmk31shACU`);
            files.push(`setup_acucob${config.acu.versionNumber}pmk32shACU`);
        }
        if (config.acu.versionNumber >= 1110) {
            files.push(`extend(R) Version ${config.acu.version} x64.exe`);
            files.push(`extend(R) Version ${config.acu.version} x86.exe`);
            files.push(`setup_acucob${config.acu.versionNumber}pmk31shACU`);
            files.push(`setup_acucob${config.acu.versionNumber}pmk32shACU`);
        }
        return files;
    },
    localDir: `${process.env.ACULOCALLOC}\\${config.acu.versionNumber}\\PU${config.acu.pu}`,
    S3Prefix: `${process.env.ACUS3PREFIX}/${config.acu.versionNumber}/PU${config.acu.pu}/`
}

const targets = { ed: EDVars, acu: ACUVars };
const targetName = (process.argv[2] || "ed").replace(/^--/, "").toLowerCase();
const target = targets[targetName];
if (!target) {
    console.error(`Unknown target "${targetName}". Use "ed" or "acu".`);
    process.exit(1);
}

async function transferAll(target) {
    const s3 = new S3Client({ region: config.s3.region });

    fs.mkdirSync(target.localDir, { recursive: true });

    const files = await listRemoteFiles(target);

    if (files.length === 0) {
        console.log(`No files found in ${target.remoteDir}`);
        return;
    }

    const downloaded = await runWithConcurrency(files, concurrency.ftp, (file) => downloadOne(target, file));

    await runWithConcurrency(downloaded, concurrency.s3, (item) => {
        const key = target.S3Prefix + item.name;
        console.log(`Uploading ${item.localPath} -> s3://${config.s3.bucket}/${key}`);
        return uploadToS3(s3, item.localPath, config.s3.bucket, key);
    });
}

async function runWithConcurrency(items, limit, worker) {
    const results = new Array(items.length);
    let next = 0;
    async function runner() {
        while (next < items.length) {
            const index = next++;
            results[index] = await worker(items[index], index);
        }
    }
    const size = Math.max(1, Math.min(limit, items.length));
    await Promise.all(Array.from({ length: size }, () => runner()));
    return results;
}

async function listRemoteFiles(target) {
    const client = new FtpClient();
    client.ftp.verbose = false;
    try {
        await client.access(ftpAccessOptions);
        const entries = await client.list(target.remoteDir);
        let files = entries.filter((entry) => entry.isFile);

        if (target.fileList.length > 0) {
            const available = new Set(files.map((file) => file.name));
            const missing = target.fileList.filter((name) => !available.has(name));
            if (missing.length > 0) {
                console.warn(`Not found on server: ${missing.join(", ")}`);
            }
            const wanted = new Set(target.fileList);
            files = files.filter((file) => wanted.has(file.name));
        }
        return files;
    } finally {
        client.close();
    }
}

async function downloadOne(target, file) {
    const client = new FtpClient();
    client.ftp.verbose = false;
    const remoteFile = path.posix.join(target.remoteDir, file.name);
    const localPath = path.join(target.localDir, file.name);
    try {
        await client.access(ftpAccessOptions);
        console.log(`Downloading ${remoteFile} -> ${localPath}`);
        await client.downloadTo(localPath, remoteFile);
        console.log(`Downloaded ${remoteFile} -> ${localPath}`);
        return { name: file.name, localPath };
    } finally {
        client.close();
    }
}

async function uploadToS3(s3, localPath, bucket, key) {
    const body = fs.createReadStream(localPath);
    await s3.send(
        new PutObjectCommand({ Bucket: bucket, Key: key, Body: body })
    );
    console.log(`Uploaded ${localPath} -> s3://${bucket}/${key}`);
}

async function main() {
    await transferAll(target);
}

main().catch((err) => {
    console.error("Failed:", err);
    process.exit(1);
});