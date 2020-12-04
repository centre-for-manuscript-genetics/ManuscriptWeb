xquery version "3.1";

(:maps the URL parammeters of an administrators ajax calls to the corresponding admin functions. Returns JSON data to communicate the success of an action:)


declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";



(:declare namespace exist = "http://exist.sourceforge.net/NS/exist";:)
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace request="http://exist-db.org/xquery/request";

declare option output:method "json";
declare option output:media-type "application/json";



import module namespace mw ="http://exist-db.org/apps/ManuscriptWeb/mw" at "mw.xql";
import module namespace admin ="http://exist-db.org/apps/ManuscriptWeb/admin" at "admin.xql";
import module namespace library="http://exist-db.org/apps/ManuscriptWeb/library" at "library.xql";
import module namespace chronology="http://exist-db.org/apps/ManuscriptWeb/chronology" at "chronology.xql";

(: the GET parameter "action" decides, which XQuery function to call:)
let $action := request:get-parameter('action','')

(: store all possible GET-parameters here:)
let $entrypoint :=  request:get-parameter('entrypoint','')
let $type := request:get-parameter('type','')
let $nodeType :=  request:get-parameter('nodeType','')
let $direction :=  request:get-parameter('direction','')
let $newText :=  request:get-parameter('newText','')
let $resourceId := request:get-parameter('resourceId','')
let $filename := request:get-parameter("filename","")

(:for facsimile zones:)
let $elementId := request:get-parameter("elementId","")
let $x := request:get-parameter("x","")
let $y := request:get-parameter("y","")
let $width := request:get-parameter("width","")
let $height := request:get-parameter("height","")
let $rotate := request:get-parameter("rotate","")


(:for library entries:)
let $libId :=  request:get-parameter('libId','')
let $title :=  request:get-parameter('title','')
let $date :=  request:get-parameter('date','')
let $isbn :=  request:get-parameter('isbn','')
let $googleBooksId :=  request:get-parameter('googleBooksId','')
let $worldCatId :=  request:get-parameter('worldCatId','')
let $publisherId :=  request:get-parameter('publisherId','')
let $authorId :=  request:get-parameter('authorId','') 
let $itemId :=  request:get-parameter('itemId','') 



(:for TextViewer:)
let $fromId := request:get-parameter('from','')
let $toId := request:get-parameter('to','')
let $pagenum := request:get-parameter('pagenum',"1")
let $fullDoc := request:get-parameter('fulldoc',false())

let $value := request:get-parameter('value','')

(:for GenGraphViewer:)
(:currently none ;) :)

(:Call/return XQuery functions depending on the value of the 'action' parameter :)
return switch ($action)
       case 'createCollection' 
            return admin:createCollection($entrypoint)
       case 'createModule'
            return admin:createModule($type)
       case 'moveNode' 
            return admin:moveModule($resourceId, $direction)
       case 'updateNodeText'
            return admin:updateNodeText($resourceId, $nodeType, $newText)
       case 'createModule'
            return admin:createModule($type)
       case 'deleteModule'
            return admin:deleteModule($resourceId)
       case 'deleteCollection'
            return admin:deleteCollection($resourceId)
       case 'getURLlabel'
            return map{"id": $resourceId, "operation" : "getURLlabel", "urllabel": mw:getAbsoluteURLpath($resourceId)}
       case "storeFacsZone"
            return admin:storeFacsZone($resourceId, $elementId, $x, $y, $width, $height, $rotate)
       case "getFacsZone"
            return mw:getFacsZone($resourceId, $elementId)
       case "getFacZones"
            return mw:getFacZones($resourceId)
       (:TEXTVIEWER REQUESTS:)
       case "getTranscript"
            return mw:getTranscript($resourceId, $pagenum, $fromId, $toId, $fullDoc)
       (:LIBRARY REQUESTS:)
       case "newItem"
            return library:newItem($entrypoint)
       case "libAddItem"
            return library:addItem($libId,$type,$title,$date,$isbn,$googleBooksId,$worldCatId,$publisherId,$authorId)
       case "libAddAuthor"
            return library:addAuthor($libId)
       case "libAddPublisher"
            return library:addPublisher($libId)
       case "libCleanUpAuthors"
            return library:cleanUpAuthors($libId)
       case "libCleanUpPublishers"
            return library:cleanUpPublishers($libId)
       case "libDelAuthor"
            return library:delAuthor($libId,$authorId)
       case "libDelItem"
            return library:delItem($libId, $itemId)
       case "libDelPublisher"
            return library:delPublisher($libId, $publisherId)
       case "libEmptyItems"
            return library:emptyItems($libId)
       (:GENGRAPHVIEWER:)
       case "getGenGraph"
            return mw:getGenGraph($entrypoint)
       (:Chronology tool:)
        case 'getEvents'
            return chronology:getEvents()
        case 'getLibraryEvents'
            return chronology:getLibraryEvents()
        (:probably not used anymore:)
        case 'getSourceEvents'
            return chronology:getSourceEvents()
        case 'getLetterEvents'
            return chronology:getLetterEvents()
        case 'getSourcesOfResource'
            return chronology:getSourcesOfResource($resourceId)
        case 'getTargetsOfResource'
            return chronology:getTargetsOfResource($resourceId)
        case 'getDocumentInfo'
            return chronology:getDocumentInfo($resourceId)
        case 'getLetterInfo'
            return chronology:getLetterInfo($resourceId)
        case 'getAuthors'
            return library:getAuthors()
        case 'changeCSSvar'
            return admin:changeCSSvar($itemId,$value)
       default return <p>the passed action cannot be processed.</p>