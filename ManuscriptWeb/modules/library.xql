xquery version "3.1";

module namespace library="http://exist-db.org/apps/ManuscriptWeb/library";
import module namespace admin = "http://exist-db.org/apps/ManuscriptWeb/admin" at "admin.xql";
import module namespace config="http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
import module namespace mw ="http://exist-db.org/apps/ManuscriptWeb/mw" at "mw.xql";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";


(:###############################################################################################:)
(:########################### GENERAL LIBRARY MODULE FUNCTIONS ##################################:)
(:###############################################################################################:)

(:empty all items from the given library, keeps authors an publishers, returns libId and success status:)
declare function library:emptyItems($libId as xs:string?){
""
};

(:remove all authors that don't occure in any item within the given library:)
declare function library:cleanUpAuthors($libId as xs:string?){
""
};

(:remove all publishers that don't occure in any item within the given library:)
declare function library:cleanUpPublishers($libId as xs:string?){
""
};


(:###############################################################################################:)
(:#############################      ITEM EDIT FUNCTIONS      ###################################:)
(:###############################################################################################:)

(:add a new item to the library with the given libId, return item information as JSON and success status:)
declare function library:addItem($libId as xs:string,$type as xs:string,$title as xs:string,
$date as xs:date?,$isbn as xs:string?,$googleBooksId as xs:string?, $worldCatId as xs:string?, $publisherRef as item()*, $authorRef as item()*  ){

        let $path := mw:getCollectionPathById($libId)
        let $configFile := doc(concat($path,'/config.xml'))
        
        
        (:should be replaced by: calling newitem(), followed by filling the new item with update:)
        let $id := admin:createUniqueID("libItem")
        let $newItem :=       
            <item id="{$id}">
                 <type>{$type}</type>
                 <title>{$title}</title>
                 <date>{$date}</date>
                 <!-- further 1:1 relation fields, such as pages, hardcover... -->
                 <isbn>{$isbn}</isbn>
                 <googleBooksId>{$googleBooksId}</googleBooksId>
                 <hathiTrustId></hathiTrustId>
                 <worldCatId>{$worldCatId}</worldCatId>
                 <!-- further identifiers -->
                 
                 <publisher ref="{for $item in $publisherRef return concat("#", $item, " ") }"/>
                 <authors ref="{for $item in $authorRef return concat("#", $item, " ") }"/>
                 <editors ref=""/>
                 <!-- what about editor? -->
            </item>
                        
        
        let $saveItem := update insert $newItem into $configFile/items
        let $createFolder := ""
        let $saveCoverThumb :=""
        
        return map {
        
                    'id'        :   $id, 
                    'libraryId' :   $libId,
                    'operation' :   'addItem', 
                    'title'     :   $title,
                    'success'   :   "true"
                    
                    }
};

(:delete the item with the given itemId from the library with the given libId, return itemId and success status :)
declare function library:delItem($libId as xs:string?, $itemId as xs:string?){
""
};
(:create a new empty item, no assets except for an ID are assigned :)
declare function library:newItem($libId as xs:string?){
     let $path := mw:getCollectionPathById($libId)
     let $configFile := doc(concat($path,'/config.xml'))
     
     let $id := admin:createUniqueID("libItem")
     let $newItem :=       
            <item xml:id="{$id}">
                 <type>book</type>
                 <title></title>
                 <date></date>
                 <!-- further 1:1 relation fields, such as pages, hardcover... -->
                 <isbn></isbn>
                 <googleBooksId></googleBooksId>
                 <hathiTrustId></hathiTrustId>
                 <worldCatId></worldCatId>
                 <!-- further identifiers -->
                 
                 <publisher ref=""/>
                 <authors/>
                 <editors/>
                 
                 <frontmatter></frontmatter>
                 <pagecount></pagecount>
                 <dimension></dimension>
            </item>

     let $saveItem := update insert $newItem into $configFile//items[1]
     (:CREATE FOLDER FOR ITEM!:)
     return map {
        'id'        :   $id, 
        'libraryId' :   $libId,
        'operation' :   'newItem', 
        'title'     :   'not set yet',
        'success'   :   "true"
     }
};


(:###############################################################################################:)
(:#############################     AUTHOR EDIT FUNCTIONS     ###################################:)
(:###############################################################################################:)


(:add a new author to the library with the given libId, return author information as JSON:)
declare function library:addAuthor($libId as xs:string?){
""
};

(:delete the author with the given authorId from the library with the given libId, return authorId and success status:)
declare function library:delAuthor($libId as xs:string?,$authorId as xs:string?){
(:Check if author is still in any  book? Don't forget the corresponding warning!:)
""
};




(:###############################################################################################:)
(:#############################   PUBLISHER EDIT FUNCTIONS    ###################################:)
(:###############################################################################################:)

(:add a new publisher to the library with the given libId, return publisher information as JSON:)
declare function library:addPublisher($libId as xs:string?){
""
};

(:delete the publisher with the given publisherId from the library with the given libId, return publisherId and success status:)
declare function library:delPublisher($libId as xs:string?,$publisherId as xs:string?){
(:Check if publisher is still in any  book? Don't forget the corresponding warning!:)
""
};




(:###############################################################################################:)
(:#############################   ITEM GETTERS AND SETTERS    ###################################:)
(:###############################################################################################:)

declare function library:item_setTitle($itemId as xs:string?, $title as xs:string?){
    let $item :=  collection($config:data-root)//id($itemId)
    let $update := update value $item//title[1] with $title

    return map {
        'id'        :   $id, 
        'libraryId' :   $libId,
        'operation' :   'setTitle', 
        'title'     :   $item//title[1],
        'success'   :   "true"
     }
};


declare function library:item_setType($itemId as xs:string?, $type as xs:string?){
    let $item :=  collection($config:data-root)//id($itemId)
    let $update := update value $item//type[1] with $type
    
    return map {
        'id'        :   $id, 
        'libraryId' :   $libId,
        'operation' :   'setType', 
        'title'     :   $item//type[1],
        'success'   :   "true"
     }
};


declare function library:item_setDate($itemId as xs:string?, $date as xs:date?){
    let $item :=  collection($config:data-root)//id($itemId)
    let $update := update value $item//date[1] with $date
    
        return map {
        'id'        :   $id, 
        'libraryId' :   $libId,
        'operation' :   'setDate', 
        'title'     :   $item//date[1],
        'success'   :   "true"
     }
};


declare function library:item_setFrontmatter($itemId as xs:string?, $frontmatter as xs:string?){
    let $item :=  collection($config:data-root)//id($itemId)
    let $update := update value $item//frontmatter[1] with $frontmatter
    
    return map {
        'id'        :   $id, 
        'libraryId' :   $libId,
        'operation' :   'setFrontmatter', 
        'title'     :   $item//fromtmatter[1],
        'success'   :   "true"
     }
};

declare function library:item_setPagecount($itemId as xs:string?, $pagecount as xs:string?){
    let $item :=  collection($config:data-root)//id($itemId)
    let $update := update value $item//pagecount[1] with $pagecount
    
    return map {
        'id'        :   $id, 
        'libraryId' :   $libId,
        'operation' :   'setPagecount', 
        'title'     :   $item//pagecount[1],
        'success'   :   "true"
     }
};


declare function library:item_setDimension($itemId as xs:string?, $dimension as xs:string?){
    let $item :=  collection($config:data-root)//id($itemId)
    let $update := update value $item//dimension[1] with $dimension
    
    return map {
        'id'        :   $id, 
        'libraryId' :   $libId,
        'operation' :   'setDimension', 
        'title'     :   $item//dimension[1],
        'success'   :   "true"
     }
};


declare function library:item_getShortTitle($itemId as xs:string?){
    let $item :=  collection($config:data-root)//id($itemId)
    let $authorRef := translate(data($item/author/@ref),"#","")
    let $author := $item/ancestor::library//id($authorRef)/lastname
    let $title := if(string-length($item//title/text()) > 20) then substring($item//title/text(),1, 20)||"..." else $item//title/text()
    
    return $author||':
"' || $title ||'"'
    
    
};



(:counts the number of sources in the library that point to a given resource (not a library item):)
declare function library:countSourcesForTargetId($targetId as xs:string?){
    let $relations := for $rel in doc($config:data-root || "/relations/libraryRelations.xml")//relation[to/@docId = $targetId]
                      let $fromdata := $rel/from/@jjdaSourceId (:this must be changed to the fromId!  :)
                      group by $fromdata
                      return <a>{count($rel)}</a>
    
    return count($relations)
};


declare function local:make-pair($e as element()) as xs:string?
{
  typeswitch($e)
    case element(data) return concat(local-name($e), '=', $e/@value)
    default return concat(local-name($e), ':', $e)
};

declare function library:getAuthors(){
    let $tableHead := doc($config:data-root || "/libraryAuthors/authorCollection.xml")//author[@type="tableHead"]
    let $authors := doc($config:data-root || "/libraryAuthors/authorCollection.xml")//author[not(@type="tableHead")]
    let $elements := for $el in $tableHead/* return $el/name()
    let $canEdit := sm:has-access(xs:anyURI($config:data-root || "/libraryAuthors/authorCollection.xml"), "w")

    return map{
        'operation' : "getAuthors",
        'success':    "true",
        'loggedIn' : $canEdit,
        'tableHead': for $element in $tableHead/* 
                        return map{ 
                            'label': normalize-space($element/text()[1]),
                            'element' : $element/name(),
                            'nOf' : if ($element/@nOf = "true") then "true" else "false"
                        },
        'data' :    
                        for $element in $authors
                        return 
                        map:merge((map{"elementID": $element/data(@xml:id)},
                            map:merge(for $els in $element/* return map:entry($els/name() , $els/text() ))  
                    ))
         }
    };