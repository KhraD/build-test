awk '
function trim(str) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", str);
    return str;
}

function print_kv(key, value) {
    if (print_kv_comma) printf ",";
    printf "\"%s\":%s", key, value;
    print_kv_comma = 1;
}

function parse_constructor(val,ctor, args_raw, arg_parts, i, k, v, n, has_colon, result) {
    ctor = gensub(/^([A-Za-z_][A-Za-z0-9_]*)\(.*$/, "\\1", 1, val);
    args_raw = gensub(/^[A-Za-z_][A-Za-z0-9_]*\((.*)\)$/, "\\1", 1, val);
    n = split(args_raw, arg_parts, /,[[:space:]]*/);
    has_colon = 0;
    for (i = 1; i <= n; i++) if (arg_parts[i] ~ /:/) { has_colon = 1; break }
    result = "";
    if (has_colon) {
        for (i = 1; i <= n; i++) {
            split(arg_parts[i], kv, /:[[:space:]]*/);
            k = trim(kv[1]); v = trim(kv[2]);
            if (v ~ /^["\047].*["\047]$/) v = gensub(/^["\047](.*)["\047]$/, "\\1", 1, v);
            v = "\"" v "\"";
            result = result (i > 1 ? "," : "") "\"" k "\":" v;
        }
        return sprintf("{\"%s\":{%s}}", ctor, result);
    } else {
        for (i = 1; i <= n; i++) {
            v = trim(arg_parts[i]);
            if (v ~ /^["\047].*["\047]$/) v = gensub(/^["\047](.*)["\047]$/, "\\1", 1, v);
            v = "\"" v "\"";
            result = result (i > 1 ? "," : "") v;
        }
        return sprintf("{\"%s\":[%s]}", ctor, result);
    }
}

BEGIN {
    FS="=";
    section = "";
    section_count = 0;
    printf "{";
    in_section = 0;
    print_kv_comma = 0;
}

/^[[:space:]]*;/ { next }

/^[[:space:]]*\[.*\]/ {
    if (in_section) printf "}";
    if (print_kv_comma) printf ",";
    section = gensub(/^[[:space:]]*\[([^\]]+)\][[:space:]]*$/, "\\1", 1);
    section_names[section_count++] = section;
    printf "\"%s\":{", section;
    in_section = 1;
    print_kv_comma = 0;
    next;
}

/^[[:space:]]*[^=[:space:]]+[[:space:]]*=/ {
    key = trim($1);
    value = trim(substr($0, index($0,"=") + 1));
    # Multiline JSON object detection
    if (value ~ /^(\{[^}]*)|(\[[^\]]*)|(\([^\)]*)$/) {
        while (getline next_line > 0) {
           if (value ~ /}$/){
              split(next_line,arr,"=",_)
              if(next_line ~ /"$/){
                  value = value ",\"" arr[1] "\":" arr[2];
              }else{
                  value = value ",\"" arr[1] "\":\"" arr[2] "\"";
              }
              break;
           }else{
              value = value next_line;
           }
           #value = value next_line;
           # if (value ~ /}/ || value ~ /]/) break;
        }
    }
    # Bizarre Objects that have their own type of formatting
    value = gensub(/(Object\(([^)]*)\))/, "{\"Object\":{\"_\":\\2 \\3}}", "g", value);
    value = gensub(/("Object":\{"_":([^,]*)([^}]*)})/, "\"Object\":{\"_\":\"\\2\" \\3}", "g", value)
    is_json = match(value, /^(\{.*\})|(\[.*\])$/);
    if (!is_json && value ~ /^[A-Za-z_][A-Za-z0-9_]*\(.*\)$/) {
        value = parse_constructor(value);
    }
    else if (!is_json && value ~ /^["\047].*["\047]$/) {
        value = gensub(/^["\047](.*)["\047]$/, "\\1", 1, value);
        gsub(/"/, "\\\"", value);
        value = "\"" value "\"";
    }
    else if (!is_json) {
        gsub(/"/, "\\\"", value);
        value = "\"" value "\"";
    }
    print_kv(key, value);
}

END {
    if (in_section) printf "}";
    printf "}";
}
'
