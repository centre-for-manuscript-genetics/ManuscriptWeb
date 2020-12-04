xquery version "3.0";

import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "modules/config.xqm";
import module namespace login = "http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "modules/mw.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $local:login_domain := "org.exist-db.ManuscriptWeb";
declare variable $local:user := $local:login_domain || '.user';



(:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
(:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
(:this function looks up which resource corresponds to a given URL-path and forwards to the corresponding viewer :)
(:$embed=true() allows to surround the viewer with templates/page.html (direct url calls),:)
(:$embed=false() loads the viewer without the surrounding navigation etc (for ajax calls) :)
(:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
(:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
declare function local:mapper($path as xs:string?, $embed as xs:boolean?){
    let $resId := mw:runIntoFolder($path, "")
    let $resType := mw:getResourceType($resId)
    let $modType := mw:getModuleType(mw:getModuleId($resId))
    
    return
        (:redirect doc resources to document-viewer.html and ... :)
        if ($modType = "library") then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{if ($embed) then $exist:controller||'/library-viewer.html' else $exist:controller||'/templates/library-content.html' }">
                    <set-header name="Cache-Control" value="no-cache"/>
                    <cache-control cache="no"/>
                    <set-attribute name="resource" value="{$resId}"/>
                </forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <set-header name="Cache-Control" value="no-cache"/>
                    </forward>
                </view>
            </dispatch>
        else
            if ($resType = "doc") then
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{if ($embed) then $exist:controller||'/document-viewer.html' else $exist:controller||'/templates/document-viewer.html'}">
                        <set-header name="Cache-Control" value="no-cache"/>
                        <cache-control cache="no"/>
                        <set-attribute name="resource" value="{$resId}"/>
                    </forward>
                    <view>
                        <forward url="{$exist:controller}/modules/view.xql">
                            <set-header name="Cache-Control" value="no-cache"/>
                        </forward>
                    </view>
                </dispatch>
            (:... all others to explorer.html :)
            else
                <dispatch  xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{if($embed) then $exist:controller||'/explorer.html' else $exist:controller||'/templates/module-content.html'}">
                        <set-header name="Cache-Control" value="no-cache"/>
                        <cache-control cache="no"/>
                        <set-attribute name="resource" value="{$resId}"/>
                    </forward>
                    <view>
                        <forward url="{$exist:controller}/modules/view.xql">
                            <set-header name="Cache-Control" value="no-cache"/>
                        </forward>
                    </view>
                </dispatch> 
};
(:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
(::::::::::::::::::::::::::::::::::::::::::END OF MAPPING FUNCTION :::::::::::::::::::::::::::::::::::::::::::::::)
(:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)











let $logout := request:get-parameter("logout", ())
let $set-user := login:set-user($local:login_domain, '/exist', (), false())
(:let $mylogin := xmldb:login("/db",'student',"student"):)

let $pages := doc($config:app-root||"/config/GeneralSettings.xml")//Section[@name="pages"]/Page

return
    
    if ($exist:path eq '') then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{request:get-uri()}/"/>
        </dispatch>
    (::::::PROCESS CALLS TO CSS FILES. THE CSS VARS ARE INCLUDED BY A MW:FUNCTION::::)
     else if(contains($exist:path, ".css")) then 
            let $requestedFile := if(contains($exist:path,"/$app/")) then substring-after($exist:path, '/$app/') else $exist:path
            return mw:process-css($requestedFile)
   
        (:$app is used  to redirect relative path requests to html-files to their absolute path starting from app-root BUT also sending
        them through exists templating module!:)
    else
        if (contains($exist:path, "/$app/") and ends-with($exist:resource, ".html")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/{substring-after($exist:path, '/$app/')}">
                    <set-header name="Cache-Control" value="no-cache"/>
                    <cache-control cache="no"/>
                </forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <set-header name="Cache-Control" value="no-cache"/>
                        <cache-control cache="no"/>
                    </forward>
                </view>
            </dispatch>
            
            (:$ For non-html file-requests, $app redirects the absolute path without going through templating....:)
        else
            if (contains($exist:path, "/$app/")) then
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/{substring-after($exist:path, '/$app/')}"></forward>
                </dispatch>
        (::::::::::::::::::::::::::::)   
        (:EXPLORER REQUEST HANDLING!:)  
        (::::::::::::::::::::::::::::)         
        else 
            if (contains($exist:path, "/$res/")) then
                let $cleanRequest := replace($exist:path,"/$res/","/")
                let $resId := mw:runIntoFolder($cleanRequest, "")
                return 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/document-viewer.html">
                        <add-parameter name="resource" value="{$resId}"/>
                    </forward>
                    <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <set-header name="Cache-Control" value="no-cache"/>
                    </forward>
                </view>
                </dispatch>
        (::::::::::::::::::::::::)   
        (:IIIF REQUEST HANDLING!:)  
        (::::::::::::::::::::::::) 
        else if (contains($exist:path, "/iiif/manifest/")) then
                <dispatch
                    xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward
                        url="{$exist:controller}/modules/iiif-calls.xql">
                        <add-parameter name="get" value="manifest"/>
                        <add-parameter name="resid" value="{substring-after($exist:path, '/iiif/manifest/')}"/>
                    </forward>
                </dispatch>
        else if (contains($exist:path, "/iiif/sequence/")) then
                <dispatch
                    xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward
                        url="{$exist:controller}/modules/iiif-calls.xql">
                        <add-parameter name="get" value="sequence"/>
                        <add-parameter name="resid" value="{substring-after($exist:path, '/iiif/sequence/')}"/>
                    </forward>
                </dispatch>
        else if (contains($exist:path, "/iiif/canvas/")) then
                <dispatch
                    xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward
                        url="{$exist:controller}/modules/iiif-calls.xql">
                        <add-parameter name="get" value="canvas"/>
                        <add-parameter name="resid" value="{substring-after($exist:path, '/iiif/canvas/')}"/>
                    </forward>
                </dispatch>       
        (::::::::::::::::::::::::::::::) 
        (:END OF IIIF REQUEST HANDLING:)
        (::::::::::::::::::::::::::::::)
        
        (::::::::::::::::::::::::::::::) 
        (: IIPImage Request Handling  :)
        (::::::::::::::::::::::::::::::)
         else if (contains($exist:path, "/iipsrv/")) then
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/modules/iip-calls.xql/{substring-after($exist:path, '/iipsrv/')}">
                        <add-parameter name="IIIF" value="{substring-after($exist:path, 'IIIF=')}"/>
                        <set-header name="Cache-Control" value="no-cache"/>
                        <cache-control cache="no"/>
                    </forward>
                </dispatch>
        (::::::::::::::::::::::::::::::) 
        (: End of IIPImage  Handling  :)
        (::::::::::::::::::::::::::::::)
        
            else
                if ($exist:path eq "/") then
                    (: forward root path to index.xql :)
                    <dispatch
                        xmlns="http://exist.sourceforge.net/NS/exist">
                        <redirect
                            url="index.html"/>
                    </dispatch>
        (::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
        (::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
        (: IF THE STRING GETPAGE/ OCCURS IN THE REQUEST: it must be an AJAX request for a template page. 
           Look up which template to serve in GeneralSettings.xml.
           For example: if GETPAGE/home/ is requested, check pages in GeneralSettings for Page[@url="home"] and 
           return the assigned template from Page/@serve
        :)
        (::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
        (::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::)
            else if(contains($exist:path,"GETPAGE/Modules/") or contains($exist:path,"GETPAGE/modules/"))then 
                let $remainingPath := substring-after(replace($exist:path,"/Modules/","/modules/"), "GETPAGE/modules/")
                (:if only /GETPAGE/Modules/ is requested without any resource, forward to templates/module-overview:)
                return if ($remainingPath="") then 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/templates/module-overview.html">
                            <set-header name="Cache-Control" value="no-cache"/><cache-control cache="no"/>
                    </forward>
                    <view><forward url="{$exist:controller}/modules/view.xql">
                            <set-header name="Cache-Control" value="no-cache"/>
                          </forward>
                   </view>
                </dispatch>
                (:else try to forward to corresponding document viewer!:)
                else local:mapper($remainingPath,false())
                
                    
            else if(contains($exist:path,"GETPAGE/"))then 
                    let $requestURL := fn:lower-case(substring-after($exist:path, "GETPAGE"))
                    let $servePage := doc($config:app-root||"/config/GeneralSettings.xml")//Section[@name="pages"]/Page[contains($requestURL,"/"||fn:lower-case(@url))][1]/data(@serve)
                    return try {
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/{$servePage}">
                            <set-header name="Cache-Control" value="no-cache"/>
                            <cache-control cache="no"/>
                        </forward>
                        <view>
                                <forward url="{$exist:controller}/modules/view.xql">
                                    <set-header name="Cache-Control" value="no-cache"/>
                                </forward>
                        </view>
                    </dispatch>}
                    catch err:notFound{<div><p>Requested Page not found</p></div>}
            
            
            (:reverse case to above TODO: comment this better!!!:)
            else if(exists($pages["/"||data(@url) = fn:lower-case($exist:path)]) or exists($pages["/"||data(@url)||"/" = fn:lower-case($exist:path)])) then
                let $url := if(exists($pages["/"||data(@url) = fn:lower-case($exist:path)])) then $pages["/"||data(@url) = fn:lower-case($exist:path)]/data(@url)
                                else $pages["/"||data(@url)||"/" = fn:lower-case($exist:path)]/data(@url)
                return 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/forward-template.html">
                        <set-attribute name="servetemplate" value="{$url}"/>
                    </forward>
                    <view>
                        <forward url="{$exist:controller}/modules/view.xql">
                            <set-header name="Cache-Control" value="no-cache"/>
                        </forward>
                    </view>
                </dispatch>
                (:
                return
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward url="{$exist:controller}/index.html">
                                <add-parameter name="urli" value="{$a}"/>
                            </forward>
                            <view>
                                <forward url="{$exist:controller}/modules/view.xql">
                                    <set-header name="Cache-Control" value="no-cache"/>
                                </forward>
                            </view>
                 </dispatch>:)
            
            (:Handle requests to /modules when they do not come via ajax (and thus do not contain /GETPAGE/modules):)
            else
                    if (fn:lower-case($exist:path) eq "/modules" or fn:lower-case($exist:path) eq "/modules/") then
                        <dispatch
                            xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward
                                url="{$exist:controller}/explorer.html">
                                <set-header name="Cache-Control" value="no-cache"/>
                                <cache-control cache="no"/>
                            </forward>
                            <view>
                                <forward
                                    url="{$exist:controller}/modules/view.xql">
                                    <set-header
                                        name="Cache-Control"
                                        value="no-cache"/>
                                </forward>
                            </view>
                        </dispatch>
                            
                           
                   
                            (:lock down /data folder from URL access:)
                            else
                                if (contains($exist:path, "/data/") and not(ends-with($exist:resource, (".png", ".PNG", ".JPG", ".jpg", ".woff", ".woff2", ".css")))) then
                                    <dispatch
                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                        <redirect
                                            url="../no-access.html"/>
                                    </dispatch>
                            (:if an image file is requested ... for now only png:)
                            else
                                    if (contains($exist:path, "/data/") and ends-with($exist:resource, (".png", ".PNG")) and sm:has-access(xs:anyURI($config:app-root || $exist:path), "r")) then
                                        <dispatch
                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                            <cache-control
                                                cache="no"/>
                                        </dispatch>
                                    else
                                        if (contains($exist:path, "/data/") and ends-with($exist:resource, (".png", ".PNG")) and not(sm:has-access(xs:anyURI($exist:path), "r"))) then
                                            <tot>{sm:has-access(xs:anyURI($config:app-root || $exist:path), "r")} - a - {sm:id()//sm:real/sm:username} -- {$config:app-root}</tot>
                                        
                                        else
                                            if (ends-with($exist:resource, ".html")) then
                                                (: the html page is run through view.xql to expand templates :)
                                                <dispatch
                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                    <view>
                                                        <forward
                                                            url="{$exist:controller}/modules/view.xql">
                                                            <cache-control
                                                                cache="no"/>
                                                            <set-header
                                                                name="Cache-Control"
                                                                value="no-cache"/>
                                                        </forward>
                                                    </view>
                                                    <error-handler>
                                                        <forward
                                                            url="{$exist:controller}/error-page.html"
                                                            method="get"/>
                                                        <forward
                                                            url="{$exist:controller}/modules/view.xql"/>
                                                    </error-handler>
                                                </dispatch>
                                                
                                         
                                            (:::::::::::::::::::::::::::::::::::::::::::::::)
                                            (:THIS IS THE URL-PATH TO REAL DOCUMENT MAPPING:)
                                            (:::::::::::::::::::::::::::::::::::::::::::::::)
                                            (:: mapping moved to function local:mapper()!:::)
                                            
                                            else
                                                if (string-length(mw:runIntoFolder($exist:path, "")) > 0) then
                                                    local:mapper($exist:path,true())
                                                
                                                (: Resource paths starting with $shared are loaded from the shared-resources app :)
                                                else
                                                    if (contains($exist:path, "/$shared/")) then
                                                        <dispatch
                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                            <forward
                                                                url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
                                                                <set-header
                                                                    name="Cache-Control"
                                                                    value="max-age=3600, must-revalidate"/>
                                                            </forward>
                                                        </dispatch>
                            (:this one can go, too?:)
                            else
                                if (contains($exist:path, "about.html")) then
                                    <dispatch
                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                        <forward
                                            url="/templates/about.html">
                                            <set-header
                                                name="Cache-Control"
                                                value="max-age=3600, must-revalidate"/>
                                        </forward>
                                    </dispatch>
                                                       
                                                        
                            else
                                (: everything else is passed through :)
                                <dispatch
                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                    <cache-control cache="yes"/>
                                    <set-header name="Cache-Control" value="private, no-store, max-age=0, no-cache, must-revalidate, post-check=0, pre-check=0"/>
                                    <!--<cache-control cache="no"/>
                                    <set-header name="Cache-Control" value="no-cache"/>-->
                                    
                                    <set-header  name="Pragma" value="no-cache"/>
                                    <set-header name="Expires" value="Fri, 01 Jan 1990 00:00:00 GMT"/>
                                </dispatch>
