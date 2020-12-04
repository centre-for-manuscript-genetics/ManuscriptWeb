module namespace iiif = "http://exist-db.org/apps/ManuscriptWeb/iiif";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
import module namespace config="http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
import module namespace mw ="http://exist-db.org/apps/ManuscriptWeb/mw" at "mw.xql";


(:return a IIIF manifest derived from a TEI transcript:)
declare function iiif:getManifest($resid as xs:string?){
    let $resource :=  collection($config:data-root)//id($resid)
    let $tsName := $resource/data(@ref)
    let $tsPath := util:collection-name($resource)||"/transcripts/"||$tsName
    
    
    
    (:compile some more metadata from the tei transcript $ts like this:)
    let $ts := doc($tsPath)
    let $sequences := $ts//tei:sourceDoc 
    let $title := $ts//tei:title[1]
   
    return if (count($sequences)>0) then map{
        '@context'          :       "http://iiif.io/api/presentation/2/context.json",
        '@id'               :       concat($config:appSourceURL,"/iiif/manifest/",$resid), (:link to manifest itself:)
        '@type'             :       "sc:Manifest",
        'label'             :       $resource/tei:label/text(),
        (:'metadata'          :       [],:)
        (:'description'       :       [
                                        map{
                                                '@value':"something",
                                                '@language':"en"
                                        }
                                    ],     :)
       (: 'license'           :       "https://creativecommons.org/licenses/by/3.0/",:)
        'attribution'       :       "", 
        'sequences'         :       [
                                        for $seq at $pos in $sequences
                                            return iiif:getSequences(concat($resid,"_",$pos))
                                    ],
        (:'structures'        :       [],:)
        'viewing-directions':       "left-to-right"
    }
    else concat("There is no IIIF resource for the requested id '",$resid,"'.")
};

declare function iiif:getSequences($resid as xs:string?){
    let $sequenceNumber := substring-after($resid, '_')
    let $simpleId := substring-before($resid, '_')
    
    let $resource :=  collection($config:data-root)//id($simpleId) (:NOT FOUND! WHY?:)
    let $tsName := $resource/data(@ref)
    let $tsPath := util:collection-name($resource)||"/transcripts/"||$tsName
    let $ts := doc($tsPath)
    let $sequences := $ts//tei:sourceDoc[$sequenceNumber]
    let $canvases := $sequences//tei:surface[@type="iiif-canvas"]
    
    return map {
            '@id'   :   concat($config:appSourceURL,"/iiif/sequence/",$resid), 
            '@type' :   "sc:Sequence",
            'label' :   "",
            'canvases' : 
                    for $canvas at $pos in $canvases
                        let $canvasLinkLocalAccess := replace($canvas/tei:graphic[1]/data(@url),"https://chambers.uantwerpen.be/images/","http://localhost/iipsrv/")
                        return 
                        
                        try {
                            iiif:getCanvas($canvasLinkLocalAccess)
                        } catch * {
                            <error>Error on canvas {$pos}: {$canvas/tei:graphic[1]/data(@url)}</error>
                        }
                        
                        
                        
    }
};
declare function iiif:getCanvas($resid as xs:string?){
   let $myDoc := json-doc($resid)
   (:replace localhost usage in manifest by the request url when iipserver is hidden behind reverse proxy:)
   let $idClean := replace($myDoc('@id'),'http://localhost/iipsrv/','https://chambers.uantwerpen.be/images/')
   let $onlyId := replace($resid,"http://localhost/iipsrv/iipsrv.fcgi\?IIIF=","")
  
   return map {
   
   
        '@id'       : concat($config:appSourceURL,"/iiif/canvas/",$onlyId),   
        '@type'     : "sc:Canvas",
        'label'     : "some label",
        'height'    :$myDoc?height,
        'width'     :$myDoc?width,
        'images':    [
                        map{
                            '@context'  :"http://iiif.io/api/presentation/2/context.json",
                            '@id'       : $idClean,
                            '@type'     :"oa:Annotation",
                            'motivation':"sc:painting",
                            'resource'  : map{
                                                '@id' : $idClean||"/info.json",
                                                '@type': "dctypes:Image",
                                                'format':"image/jpeg",
                                                'width':$myDoc?width,
                                                'height':$myDoc?height,
                                                'service': map{
                                                                    '@context':"http://iiif.io/api/image/2/context.json",
                                                                    '@id': $idClean,
                                                                    'profile' : $myDoc?profile
                                                            }
                                            },
                            'on'        : concat($config:appSourceURL,"/iiif/canvas/",$onlyId)
                            
                        }]
                    ,
        'related':""
        
   } 

};
