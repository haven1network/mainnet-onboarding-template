export function identity<T>(arg: T): T {
    return arg;
}

export function strToBool(s: string): boolean {
    return s.trim().toLowerCase() == "true";
}

export function boolToStr(b: boolean): string {
    return b ? "true" : "false";
}

export function strToNum(s: string): number {
    return +s;
}

export function strToInt(s: string): number {
    return ~~+s;
}

export function strToBigint(s: string): bigint {
    return BigInt(strToInt(s));
}
