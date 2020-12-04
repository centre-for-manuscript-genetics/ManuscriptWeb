module namespace chronology = "http://exist-db.org/apps/ManuscriptWeb/chronology";

import module namespace config="http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
import module namespace mw ="http://exist-db.org/apps/ManuscriptWeb/mw" at "mw.xql";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
import module namespace library ="http://exist-db.org/apps/ManuscriptWeb/library" at "library.xql";

declare function chronology:getEvents(){
    let $test := "test"
    (:
    
        "drafts":  map {"events": chronology:getDraftsEvents()},
        "notebooks" :   map {"events": chronology:getNotebooksEvents()},
        "library" :     map {"events": chronology:getLibraryEvents()},
        "editions" :      map {"events": chronology:getEditionsEvents()}
    :)
    
    return [ 
       map {
                "group" : "Notebooks",
                "data": chronology:getNotebookEvents()
        }(:,
        map {
                "group" : "Library",
                "data": [chronology:getLibraryEvents()]
        }:)
    ]
};


(:Function not used anymore (I think).. too slow. remove? :)
declare function chronology:getSourceEvents(){
    let $allRels := doc("../data/relations/libraryRelations.xml")//relation 
    let $relations := distinct-values($allRels/to/data(@docId))
 
                 
    for $rel in $relations 
        let $specificRels := $allRels[to/data(@docId) = $rel]
        return concat($rel, ":" , count($specificRels) )
   
};

declare function chronology:getLibraryEvents(){


  let $e :=  for $item in doc(concat($config:data-root,"/modules/library-30875cef/jjda-library.xml"))//item[type/text()="book" and not(date/@uncertain or date/@range)] 
        let $date := tokenize(tokenize($item/date/text(),'\s')[last()],";")[1] 
        group by $date 
        order by $date
        return map{
            "labelVal" : count($item) || " Book(s)",
            "resourceID":"",
            "timeRange": [
                        xs:date($date||"-01-01"),
                        xs:date($date||"-12-31")
                    ],
            "val":count($item)}
    
   
  return [ 
       map {
                "group" : "Library",
                "data": $e
        }
    ]
   
};

declare function chronology:getLetterEvents(){
    let $e := for $item in doc(concat($config:data-root,"/modules/letters-joyce/config2.xml"))//row[not(contains(NotBefore/text(),"-00") or contains(NotAfter/text(),"-00") or contains(NotBefore/text(),"x") or contains(NotAfter/text(),"x"))]
        let $date := $item/NotBefore/text()
        order by $date 
        return map{
            "labelVal": "To: " || $item/LastName/text()||", "||  $item/FirstName/text(),
            "resourceID":  $item/ID/text(),
            "timeRange" : [
                        xs:dateTime($item/NotBefore/text()||"T00:00:00"),
                        xs:dateTime($item/NotAfter/text()||"T23:59:59")
            ],
            "color" : "#ebcf34",
            "val" : "0"
        }
    return [
        map {
                "group" : "Letters",
                "data" : $e
        }
    
    ]
};


declare function chronology:getNotebookEvents(){
    let $nbs := mw:getNotebookTS()   (:collection(concat($config:data-root, "/modules/notes-buffalo"))//tei:TEI[.//tei:date/@type="mw-chronology"]:)
    let $nbs_ordered := for $nb in $nbs order by $nb//tei:date[@type="mw-chronology"]/@notBefore return $nb[.//tei:date/@type="mw-chronology"]
    
    for $doc in $nbs_ordered
    let $count := library:countSourcesForTargetId(mw:getDocumentIdFromTSNode($doc))
    return map {
        "labelVal": $doc//tei:title[1]/text(),
        "timeRange": [
                        xs:date($doc//tei:date[@type="mw-chronology"]/@notBefore),
                        xs:date($doc//tei:date[@type="mw-chronology"]/@notAfter)
                    ],
        "resourceID": mw:getDocumentIdFromTSNode($doc),
        "val" : xs:string($count)
    }
};


declare function chronology:getSourcesOfResource($resId as xs:string?){
    let $sources := for $d in distinct-values(collection( concat($config:data-root, "/relations"))//relation[to/@docId = $resId]/from/@jjdaSourceId)
                    let $items := collection(concat($config:data-root, "/relations"))//relation[to/@docId = $resId][from/@jjdaSourceId=$d]
                    let $allauth := doc(concat($config:data-root, "/sources.xml"))//dl[data(@id)=$d]
                    let $author := $allauth//sauthor
                    let $title := $allauth//span
                    return map {
                                    "id" : $d,
                                    "title" : $title,
                                    "data": for $item in $items return map{
                                                "phraseId"  : $item/to/data(@phraseId),
                                                "citInfo"   : $item/citationInfo/child::node(),
                                                "cit"       : $item/quote/*,
                                                "author"    : $author,
                                                "theD"      : $d                                                
                                            }
                    }
    return $sources
};



declare function chronology:getTargetsOfResource($resId as xs:string?){
    let $targets := for $d in distinct-values(collection( concat($config:data-root, "/relations"))//relation[from/@docId = $resId]/to/@docId)
                    let $items := collection(concat($config:data-root, "/relations"))//relation[from/@docId = $resId and to/@docId=$d]
                    let $dTitle := mw:getResourceLabel($d)
                    return map {
                                    "id" : $d,
                                    "title": $dTitle,
                                    "data": for $item in $items return map{
                                                "toPhraseId"  : $item/to/data(@phraseId),
                                                "fromPhraseId" : $item/from/data(@phraseId),
                                                "theD"      : $d                                                
                                            }
                    }
    return $targets
    
};

declare function chronology:getDocumentInfo($resourceId as xs:string?){
    let $tsName := doc(mw:getCollectionPathById($resourceId)||"/mapping.xml")//transcript[1]/data(@ref)
    let $tsId := doc(mw:getCollectionPathById($resourceId)||"/mapping.xml")//transcript[1]/data(@xml:id)
    let $path := doc(mw:getCollectionPathById($resourceId)||"/transcripts/"||$tsName)//tei:TEI
    let $phraseRelationCount := count(collection(concat($config:data-root, "/relations"))//relation[to/@docId = $resourceId])
    return map{
                    "tsFileName": $tsName,
                    "titel":$path//tei:title[1]/text(),
                    "author" : $path//tei:author/text(),
                    "editor":$path//tei:editor/text(),
                    "sourceCount" : library:countSourcesForTargetId($resourceId),
                    "sourcePhraseCount" : $phraseRelationCount
                   
                    
              }
};

declare function chronology:getLetterInfo($resourceId as xs:string?){
    let $data := doc(concat($config:data-root,"/modules/letters-joyce/config2.xml"))//row[./ID/text() = $resourceId]
    return $data
};