xquery version "3.0";

import module namespace apputil="http://exist-db.org/xquery/apps" at "apputil.xql";

declare namespace install="http://exist-db.org/apps/dashboard/install";
declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=application/json";

declare %private function install:require-dba($func as function() as item()*) {
    if (xmldb:is-admin-user(xmldb:get-current-user())) then
        $func()
    else
        response:set-status-code(403)
};

let $action := request:get-parameter("action", "install")
let $package-url := request:get-parameter("package-url", ())
let $server-url := request:get-parameter("server-url", ())
let $upload := request:get-uploaded-file-name("uploadedfiles[]")
return
    install:require-dba(function() {
        if (exists($upload)) then
            <result>
            {
                try {
                    let $docName := apputil:upload(xs:anyURI($server-url))
                    return
                        <json:value json:array="true">
                            <file>{$docName}</file>
                        </json:value>
                } catch * {
                    <json:value json:array="true">
                        <error>{$err:description}</error>
                    </json:value>
                }
            }
            </result>
        else
            switch ($action)
                case "remove" return
                    let $type := request:get-parameter("type", ())
                    let $removed := apputil:remove($package-url)
                    return
                        if ($removed) then
                            <status><ok/></status>
                        else
                            <status><error>Failed to remove package {$package-url}</error></status>
                default return
                    try {
                        apputil:install-from-repo((), xs:anyURI($package-url), xs:anyURI($server-url || "/find?name="))
                    } catch * {
                        <status>
                            <error>{$err:description}</error>
                            <trace>{$exerr:xquery-stack-trace}</trace>
                        </status>
                    }
    })