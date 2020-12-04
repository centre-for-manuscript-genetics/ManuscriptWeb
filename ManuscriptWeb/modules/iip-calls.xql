xquery version "3.1";

import module namespace hc="http://expath.org/ns/http-client";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace functx="http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";



let $iipResource :=  string-join(request:get-parameter("IIIF",""))
(:check in access restriction file if requested URI is listed and not access restricted. :)
let $checkURI := functx:substring-before-last($iipResource,".tif")||".tif"
let $imgListItem := doc($config:data-root||"/restrictImages.xml")//image[@uri = $checkURI][1]
let $isAccessRestricted := if ( $imgListItem/data(@hidden) = "true") then true() else false()
let $isLoggedIn := sm:is-authenticated()

return if ($isAccessRestricted and $isLoggedIn or not($isAccessRestricted)) then

let $file-url := "http://localhost/iipsrv/iipsrv.fcgi?IIIF=" || $iipResource
let $request := <hc:request href="{$file-url}" method="GET"/>
let $response := hc:send-request($request)

let $head := $response[1]

return
        (: check to ensure the remote server indicates success :)
        if ($head/@status = '200') then
            (: try to get the filename from the content-disposition header, otherwise construct from the $file-url :)
            let $filename := 
                if (contains($head/hc:header[@name='content-disposition']/@value, 'filename=')) then 
                    $head/hc:header[@name='content-disposition']/@value/substring-after(., 'filename=')
                else 
                    (: use whatever comes after the final / as the file name:)
                    replace($file-url, '^.*/([^/]*)$', '$1')
            (: override the stated media type if the file is known to be .xml :)
            let $media-type := $head/hc:body/@media-type
            let $mime-type := 
                if (ends-with($file-url, '.xml') and $media-type = 'text/plain') then
                    'application/xml'
                else 
                    $media-type
            (: if the file is XML and the payload is binary, we need convert the binary to string :)
            let $content-transfer-encoding := $head/hc:body[@name = 'content-transfer-encoding']/@value
            let $body := $response[2]
            let $file := 
                if (ends-with($file-url, '.xml') and $content-transfer-encoding = 'binary') then 
                    util:binary-to-string($body) 
                else if(ends-with($file-url, '.json')) then
                    util:base64-encode(replace(util:binary-to-string($body),'http://localhost/iipsrv/','https://chambers.uantwerpen.be/images/'))
                    
                else $body
            return
                response:stream-binary($file,$mime-type,$filename)
                
        else
            let $status := response:set-status-code(404)
            let $type := response:set-header("Content-Type","text")
            return "IIIF: incorrect region format"
            
else 

(:ELSE -  NO ACCESS - SHOW PLACEHOLDER INSTEAD OF IMAGE!:)

let $file-url := "http://localhost/iipsrv/iipsrv.fcgi?IIIF=Placeholder.tif" || substring-after($iipResource,".tif")
let $request := <hc:request href="{$file-url}" method="GET"/>
let $response := hc:send-request($request)

let $head := $response[1]

return
        (: check to ensure the remote server indicates success :)
        if ($head/@status = '200') then
            (: try to get the filename from the content-disposition header, otherwise construct from the $file-url :)
            let $filename := 
                if (contains($head/hc:header[@name='content-disposition']/@value, 'filename=')) then 
                    $head/hc:header[@name='content-disposition']/@value/substring-after(., 'filename=')
                else 
                    (: use whatever comes after the final / as the file name:)
                    replace($file-url, '^.*/([^/]*)$', '$1')
            (: override the stated media type if the file is known to be .xml :)
            let $media-type := $head/hc:body/@media-type
            let $mime-type := 
                if (ends-with($file-url, '.xml') and $media-type = 'text/plain') then
                    'application/xml'
                else 
                    $media-type
            (: if the file is XML and the payload is binary, we need convert the binary to string :)
            let $content-transfer-encoding := $head/hc:body[@name = 'content-transfer-encoding']/@value
            let $body := $response[2]
            let $file := 
                if (ends-with($file-url, '.xml') and $content-transfer-encoding = 'binary') then 
                    util:binary-to-string($body) 
                else if(ends-with($file-url, '.json')) then
                    util:base64-encode(replace(util:binary-to-string($body),'http://localhost/iipsrv/','https://chambers.uantwerpen.be/images/'))
                else $body
            return
                response:stream-binary($file,$mime-type,$filename)
                
        else
            let $status := response:set-status-code(404)
            let $type := response:set-header("Content-Type","text")
            return "IIIF: incorrect region format"



 (:   <error>
        <message>You do not have access to this resource</message>
        {$checkURI},
        access restricted: {$isAccessRestricted},
        logged in: {$isLoggedIn}
    </error>:)