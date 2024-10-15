/* IMPORT NODE MODULES
================================================== */
import * as fs from "fs";
import * as path from "path";

/* TYPES
================================================== */
type Obj = Record<string, unknown>;

/* WRITE
================================================== */
/**
 *  Basic implementation of a JSON file writer. It will prepend the filename
 *  with the current timestamp to avoid clashes. Cannot be used to append data.
 *
 *  If the directory does not exist, this function will create it.
 *
 *  @function   writeJSON
 *
 *  @param      {string}    filePath - The relative file path. Must end in ".json"
 *  @param      {Obj}       content -  The content to write.
 *
 *  @returns    {boolean}   True is success, false otherwise.
 */
export function writeJSON(filePath: string, content: Obj): boolean {
    if (!filePath.endsWith(".json")) {
        return false;
    }

    const t = Date.now();

    let p = path.join(process.cwd(), filePath);
    const f = `${t}_${path.basename(p)}`;
    const dir = path.dirname(p);

    p = path.join(dir, f);

    try {
        const exists = fs.existsSync(dir);
        if (!exists) {
            fs.mkdirSync(dir, { recursive: true });
        }

        const d = JSON.stringify(content, null, 4);
        fs.writeFileSync(p, d, "utf8");
    } catch (e) {
        console.error(e);
        return false;
    }

    return true;
}
