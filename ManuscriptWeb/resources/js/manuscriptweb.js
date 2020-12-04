
/* An array of all existing diggers (DIGFast canvases) */
/* todo: is this neccessary AND if: are diggers removed from this array when not used anymore --> bad design! potential for dublicate ID's! */
diggers =[];

$('body').on("click", ".breadcrumb-toggle", function () {
    $("div.breadcrumbs").toggle('slow');
}).on('change', '#transcriptSelection', function () {
    var resid = $(this).find(':selected').data('resourceid');
    var filename = $(this).find(':selected').data('filename');
    //console.log(resid + "----" + filename);
    
    loadDoc("$app/modules/ajax-calls.xql?action=getTranscriptFile&resourceId=" + resid + "&filename=" + filename,
    function (e) {
        var data = e.responseText;
        $('#transcript').empty().append(data);
        //remove empty node garbage
        clean(document.body);
    });
}).on("click", ".explorer-link", function (e) {
    if ($(e.target).hasClass('btn') || $(e.target).hasClass('editable-text') || $(e.target).parent().hasClass('editable-text') || $(e.target).hasClass('adminchange')) return
    processExplorerLink(this)
}).on("click", ".libraryItem", function () {
    var bookid = $(this).data("bookid");
    //request the book info as json data
    //inside request: new window, fill it with book info!
    var bookWindow = new DraggableWindow("Book: " + bookid);
    $(bookWindow.content).load("$app/templates/bookPreview.html?libraryid=blala&bookid=" + bookid);
})
//if the facsimile-transcript button (radio button) changes, load the corresponding view
.on("change", ".ft_btn", function () {
    var resource = $(this).data("resource");
    var value = $(this).val();
    
    // $.wait(function(){ $("#content").load("$app/templates/document-viewer.html?view="+value+"&resource="+resource); }, 200)
    $("#content").load("$app/templates/document-viewer.html?view=" + value + "&resource=" + resource);
    //alert($(this).val());
}).on("click", ".facsimile-link", function (e) {
    if ($(e.target).hasClass('btn') || $(e.target).hasClass('editable-text') || $(e.target).parent().hasClass('editable-text') || $(e.target).hasClass('adminchange')) return
    
    var facsimileId = $(this).parent().data("resourceid");
    var facsimileWindow = new DraggableWindow("Facsimile: " + facsimileId);
    $(facsimileWindow.content).load("$app/templates/imagePreview.html?facsimileid=" + facsimileId);
}).on("click", ".iv-thumb-link", function (e) {
    $(".iv-thumb-link").removeClass('active');
    $(this).addClass('active');
    var imgNum = $(this).data("imgnum");
    newBrowserURL = updateURLparameter("imgnum", imgNum)
    urlParams = "&" + newBrowserURL.split("?")[1];
    var facsimileId = $(this).data("resourceid");
    //alert("this thumbnail has been clicked:" + facsimileId);
    loader("Image", ".iv-content");
    $(this).closest(".imageViewer").find(".iv-content").load("$app/templates/imagePreview.html?facsimileid=" + facsimileId + urlParams, function () {
        history.pushState('some data', 'some title', newBrowserURL);
    });
    
    //scroll active thumbnail into the center of the viewport
    var offset = $(this).offset().left - $(this).parent().offset().left - $("#imageViewField").width() / 2 + $(this).width() / 2;
    $("div.iv-thumbslider").animate({
        scrollLeft: "+=" + offset
    },
    400);
}).on("click", ".viewchange", function (e) {
    //show the spinn loader meanwhile
    loader("#content", "Viewer");
    //get id of document
    var docid = $("#theDocument").data("resourceid");
    //get view setting
    var viewsetting = $(this).data("view")
    //change the view menu to the current view
    menuChangeDocumentView(docid, viewsetting);
    $("#content").load("$app/templates/document-viewer.html?view=" + viewsetting + "&resource=" + docid);
}).on("click", ".tv-pagi:not(.disabled)", function (e) {
    var pagenum = $(this).attr("data-pagenum");
    //alert(pagenum);
    var tsID = $("#textViewField").find(".transcriptSelect option[selected]").data('file');
    var where = $("#textViewField div.editContainer")
    tvGetTS(where, tsID, pagenum,function(){chron_loadSources();});
    //here the mirador viewer is changed
     if (typeof mira_loadViewer === "function"){
    mira_loadViewer(tsID,canvasIndex = pagenum-1);}
    //load the matching sources on the left side
    //chron_loadSources();
    history.pushState('some data', 'some title', updateURLparameter("pagenum", pagenum));
    $(".iv-thumb-link.active").next(".iv-thumb-link").click();
}).on("click", ".gengraphBtn", function(e){
    var GenWindow = new DraggableWindow('Genetic Graph Viewer');
    $(GenWindow.content).load("$app/templates/GeneticGraphViewer.html");
}).on("click", ".openChronDocBtn", function(e){
    var where = "#textViewField";
    var what = $(this).data("resource");
    $(where).load("$app/templates/text-viewer.html?resource=" + what);
    
}).on( "mouseenter mouseleave", ".chron-phraseLink", function(e){
    $(".result_hover").removeClass("result_hover");
    $("tei-item[id='"+  $(this).data('toref')  + "']").addClass("result_hover");
/* On "input",the current css changes, only on "change" the update is also sent to the server! */
})

//MORE EVENT LISTENERS HERE!
;



/* change the value of the menu item View and push a new browser history state */
function menuChangeDocumentView(id, view) {
    history.pushState('some data', 'some title', updateURLparameter("view", view));
    $(".viewchange").removeClass("active");
    $(".viewchange[data-view='" + view + "']").addClass("active");
};




/* if explorer links are clicked this function is called to load their content via ajax and manipulate the browser history */
function processExplorerLink (event) {
    var where = "#content";
    // the full long URL not API encoded! this is wrong!
    //var what = $(event).data('explorerurl')
    var what = "GETPAGE"+$(event).data('shownurl');
    //alert(what);
    loadContent(where, what);
    if ($(event).data('shownurl')) {
        //console.log("adding to browser stack: " + $(event).data('shownurl') + what );
        history.pushState('data to be passed', 'Title of the page', absolutePath+$(event).data('shownurl'));
    }
};

/* this is to attach and detach content from the main content area to a window. probably not in use anymore! */
//TODO: put this on body! otherwise won't work when contents are called via Ajax
$('.detach-button').on("click", function () {
    var detachedWindow = new DraggableWindow('Transcript VI.B.01');
    var myId = $(this).parents("div.content-card").attr('id');
    
    $(detachedWindow.content).append(cardToWindow(myId));
    
    //hide the card placeholder
    $('#' + myId).hide();
    //hide the "detach button" in then nav
    $(this).hide();
    var tmpDetButton = this;
    
    // add an "re-attach function" to the default closing function of the window: when window is closed, content is reattached to card
    detachedWindow.addCustomClosingFunction(
    //this is the re-attach function:
    function () {
        $('#' + myId).prepend($(detachedWindow.content).find('nav'));
        $('#' + myId).find("div.card-body").append($(detachedWindow.content).find('div.windowcont-content').children());
        $('#' + myId).show();
        $(tmpDetButton).show();
    });
});

/* todo: check if still in use! should be obsolete */
function traceCounter(increase) {
    var num = $("input.happyInput").attr("placeholder")
    $("input.happyInput").attr("placeholder", parseInt(num) + parseInt(increase))
};



/* function to load contents into whatever element is selected */
function loadContent(whereSelector, URLrequest) {
    $(whereSelector).load(URLrequest);
}



/* turns the contents of a bootstrap card (with nav on top) into a windowcont-wrapper that can be displayed on a windowmanager window
 * todo: check if still in use? if not should later be redone. it should be possible to pull viewers on windows!*/
function cardToWindow(cardId) {
    var parentDiv = document.createElement('div');
    parentDiv.classList.add("windowcont-wrapper");
    $(parentDiv).data("prevId", cardId);
    
    var topNav = document.createElement("div");
    topNav.classList.add("windowcont-header");
    $(topNav).append($("#" + cardId).find('nav'));
    var windowBody = document.createElement("div");
    windowBody.classList.add("windowcont-content");
    $(windowBody).append($("#" + cardId).find('div.card-body').children());
    
    parentDiv.append(topNav);
    parentDiv.append(windowBody);
    
    return parentDiv;
}

/* just a function to get some waiting time for animations
 * Todo: check if still in use*/
$.wait = function (callback, ms) {
    return window.setTimeout(callback, ms);
}


/* this produces the loading spinner with the passed text at the position of the given jquery selector */
function loader(text, selector) {
    var loader = '<div>\
    <div class="sk-cube-grid">\
    <div class="sk-cube sk-cube1"></div>\
    <div class="sk-cube sk-cube2"></div>\
    <div class="sk-cube sk-cube3"></div>\
    <div class="sk-cube sk-cube4"></div>\
    <div class="sk-cube sk-cube5"></div>\
    <div class="sk-cube sk-cube6"></div>\
    <div class="sk-cube sk-cube7"></div>\
    <div class="sk-cube sk-cube8"></div>\
    <div class="sk-cube sk-cube9"></div>\
    </div>\
    <div class="sk-cube-caption">Loading ' + text + '...</div>\
    </div>';
    $(selector).html(loader);
}

/* Used to load documents if there is a recall neccessary*/
function loadDoc(url, cfunc) {
    var xhttp;
    xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function () {
        if (xhttp.readyState == 4 && xhttp.status == 200) {
            cfunc(xhttp);
        }
    };
    xhttp.open("GET", url, true);
    xhttp.send();
}


/* this ensures that the page is reloaded after the browser-history is accessed with the browser's back and forth buttons
 * this is neccessary because the URLs are changed via history.pushState when pages change via ajax.
 * 
 * note: if the location is changed via hash (links to anchors), no reload is executed!
 * */
$(window).bind('load', function () {
    setTimeout(function () {
        $(window).bind('popstate', function () {
            if(!location.hash){
                location.reload();
                alert("reload");
            }
            else{
                location.hash = location.hash.toString();
            }
        });
    },
    0);
});


/*$(document).ready(function( $ ) {
   //Use this inside your document ready jQuery 
   $(window).on('popstate', function() {
        console.log(location);
        alert("gutesWetter");
        location.reload(true);
   });
});




window.addEventListener( "pageshow", function ( event ) {
  var historyTraversal = event.persisted || 
                         ( typeof window.performance != "undefined" && 
                              window.performance.getEntriesByType("navigation")[0].type === "back_forward" );
  if ( historyTraversal ) {
    // Handle page restore.
    window.location.reload();
  }
});*/




/* update a url parameter and return the new url */
function updateURLparameter(param, paramVal) {
    //take current URL but remove / at the end
    var url = window.location.href.replace(/\/$/, '');;
    var TheAnchor = null;
    var newAdditionalURL = "";
    var tempArray = url.split("?");
    var baseURL = tempArray[0];
    var additionalURL = tempArray[1];
    var temp = "";
    
    if (additionalURL) {
        var tmpAnchor = additionalURL.split("#");
        var TheParams = tmpAnchor[0];
        TheAnchor = tmpAnchor[1];
        if (TheAnchor)
        additionalURL = TheParams;
        
        tempArray = additionalURL.split("&");
        
        for (var i = 0; i < tempArray.length; i++) {
            if (tempArray[i].split('=')[0] != param) {
                newAdditionalURL += temp + tempArray[i];
                temp = "&";
            }
        }
    } else {
        var tmpAnchor = baseURL.split("#");
        var TheParams = tmpAnchor[0];
        TheAnchor = tmpAnchor[1];
        
        if (TheParams)
        baseURL = TheParams;
    }
    
    if (TheAnchor)
    paramVal += "#" + TheAnchor;
    
    var rows_txt = temp + "" + param + "=" + paramVal;
    return baseURL + "?" + newAdditionalURL + rows_txt;
}

/* request a transcript via ajax! */
function tvGetTS(where, tsID, page, callback) {
    //alert("picking up: "+page);
    $. get ("$app/modules/ajax-calls.xql?action=getTranscript&resourceId=" + tsID + "&pagenum=" + page, function (data) {
        var file = data.data;
        var c = new CETEI();
        c.addBehaviors({ "handlers": {
                // Overrides the default ptr behavior, displaying a short link
                "ptr": function (elt) {
                    var link = document.createElement("a");
                    link.innerHTML = elt.getAttribute("target").replace(/https?:\/\/([^\/]+)\/.*/, "$1");
                    link.href = elt.getAttribute("target");
                    return link;
                },
                // Adds a new handler for <term/>, wrapping it in an HTML <b/>
                "term": function (elt) {
                    var b = document.createElement("b");
                    b.innerHTML = elt.innerHTML;
                    return b;
                },
                // Inserts the first array element before tei:add, and the second, after.
                // "add":[ "<sup>+</sup>", "<sup>+</sup>"],
                
                "item":["<span style='font-size: smaller; color: darkgrey;  left: 0.2em; '>$@n</span>"],
               
                
                //FW Edition
                "l":["<span style='font-size: x-small; color: darkgrey;  left: 0.2em; margin-left: 1em; margin-right: 1em;'>$@id</span>"]
                
               
                
                
            }
        });
        c.makeHTML5(file, function (dataset) {
            $(where).html(dataset);
            $("tei-div[type='page_verso']").hide()
            $("tei-note[type='all_notes']").hide();
            $("tei-teiHeader").hide();
            setPaginator(data.pageNum, Math.max(data.divPageCount, data.pbCount));
        });
        //callback must be executed within the $.get - callback!
        callback();
    });
    //$(where).html("<p>"+tsID+"</p>");
    
}


function setPaginator(pageNum, numOfPages) {
    pageNum = parseInt(pageNum);
    numOfPages = parseInt(numOfPages);
    $(".tv-pagi-first").attr("data-pageNum", "1");
    $(".tv-pagi-prev").attr("data-pageNum", pageNum > 1 ? pageNum - 1: 1).find("a").html(pageNum > 1 ? pageNum - 1: 1);
    $(".tv-pagi-curr").attr("data-pageNum", pageNum).find("a").html(pageNum);
    $(".tv-pagi-next").attr("data-pageNum", pageNum + 1 <= numOfPages ? pageNum + 1: pageNum).find("a").html(pageNum + 1 <= numOfPages ? pageNum + 1: pageNum);
    $(".tv-pagi-last").attr("data-pageNum", numOfPages > pageNum ? numOfPages: pageNum);
    
    $(".tv-pagi-curr").addClass('disabled');
    if (pageNum == 1) {
        $(".tv-pagi-first").addClass('disabled');
        $(".tv-pagi-prev").hide();
    } else {
        $(".tv-pagi-first").removeClass('disabled');
        $(".tv-pagi-prev").show();
    }
    if (numOfPages < pageNum + 1) {
        $(".tv-pagi-next").hide();
    } else {
        $(".tv-pagi-next").show();
    }
};



function loadDetail(evtData){
            // empty the previous accordion
            console.log("loading detail for: " )
            type = evtData.group;
            
            if(type=="Notebooks")
            {
                        loader("Sources","#source-accordion");
                         $("#sourceField").css('visibility', 'visible');
                         $("#targetField").css('visibility', 'visible');
                         
                        resourceId = evtData.data.resourceID;
                        //populate the text viewer
                        $.get("$app/modules/ajax-calls.xql?action=getDocumentInfo&resourceId="+resourceId,function(data){
                            var where = "#textViewField";
                            console.log(data);
                            $(where).empty();
                            $(where).html("<div id='textViewInfo'><h3>Your selection: "+data.titel+"</h3></div>");
                            $("#textViewInfo").append("<hr/><h5>Library:</h5><p>We recorded "+data.sourceCount+" source-documents for this resource in the library. These documents have a total of "+data.sourcePhraseCount+" phrase-level relations  to this document (=reading notes). You can browse the sources on the left. Click on a source to open its phrase-level relations to "+data.titel+".</p>");
                            $("#textViewInfo").append("<h5>Succeeding Drafts:</h5><p>This document connects to ZZ later documents with a total of MM phrase level relations. You can browse them on the right side.</p>");
                            $("#textViewInfo").append("<h5>Letters:</h5><p>For the time period in which this document was written we recorded XX letters to YY different addressees.</p>");
                            $("#textViewInfo").append("<h5>Browse this document:</h5><p>You can also open this document and browse through the transcript. The ingoing (left) and outgoing (right) phrase-level relations will adjust dynamically to show only relations to the page you are currently viewing.</p>");
                            $("#textViewInfo").append("<button class='btn btn-mw-outline my-2 my-sm-0 openChronDocBtn' data-resource='"+resourceId+"'>Open "+data.titel+"</button>");
                            //var what = resourceId;
                            //$(where).load("$app/templates/text-viewer.html?resource=" + what);
                        });
                        
                        //populate the sources
                         $.get ("$app/modules/ajax-calls.xql?action=getSourcesOfResource&resourceId="+resourceId, function (data) {
                            $("#source-accordion").empty();
                            $.each(data, function(index, element) {
                                     $("#source-accordion").append(createSourceList(element));
                                 });
                         });  
                         
                         //populate the targets
                         $.get("$app/modules/ajax-calls.xql?action=getTargetsOfResource&resourceId="+resourceId, function(data){
                            var test =[];
                            test.push(data);
                            
                            $("#target-accordion").empty();
                            $.each(test, function(ind, elem){
                                    $("#target-accordion").append(createTargetList(elem));
                                });
                         });
         } else if (type=="Library"){
                $("#textViewInfo").empty();
                $("#target-accordion").empty();
                $("#source-accordion").empty();
                
                
         } else if(type=="Letters"){
                $("#textViewInfo").empty();
                $("#target-accordion").empty();
                $("#source-accordion").empty();
                $("#sourceField").css('visibility', 'hidden');
                $("#targetField").css('visibility', 'hidden');
                
                 resourceId = evtData.data.resourceID;
                 $.get("$app/modules/ajax-calls.xql?action=getLetterInfo&resourceId="+resourceId,function(data){
                     console.log(data);
                     var where = "#textViewField";
                        $(where).empty();
                        $(where).html("<div id='textViewInfo'><h3>Letter to: "+data.FirstName+ " "+ data.LastName +  "</h3></div>");
                        //if the letter was written on a distinct date
                        const notBefore = new Date(data.NotBefore);
                        const notAfter = new Date(data.NotAfter);
                        if(datesAreOnSameDay(notBefore,notAfter)){
                        
                            $("#textViewInfo").append("<hr/><h5>Dating:</h5><p>This letter was written on "+ data.NotBefore +"</p>");
                        } else{
                            $("#textViewInfo").append("<hr/><h5>Dating:</h5><p>This letter was written between </p>");
                        }
                       
                       
                       $("#textViewInfo").append("<h5>Address:</h5><p>"+ data.SenderAddress+"</p>");
                       $("#textViewInfo").append("<h5>Repository:</h5><p>"+data.Repository+"</p>");
                       $("#textViewInfo").append("<h5>Catalogue Number(s):</h5><p>"+data.CatalogueNumbers+"</p>");
                       
                       $("#textViewInfo").append("<h5>Transcript:</h5><p style='color:red'>not available yet</p>");
                     
                    
             
                 });
                
         }         
             
             
             
             
};

function createSourceList(dates){
    var parent = $(document.createElement('div')).attr("class","card sourceRef");
    var header = $(document.createElement('div')).attr({"class" : "card-header", "id" : dates.id});
        var title = dates.title ? dates.title : "<span style='color:red'>"+dates.id+"</span>";
        var headline = $(document.createElement('h5')).attr("class","mb-0");
        var button = $(document.createElement('div')).attr({
                                                            "class" : "sourceLinkHeader", 
                                                            "data-toggle"    : "collapse",
                                                            "data-target"    : "#collapse_"+dates.id,
                                                            "aria-expanded"  : "true",
                                                            "aria-controls"  : "collapse_"+dates.id
                                                         });
        $(button).html(title ? title : "<span style='color:red'>no title found</span>");
        headline.append(button);
        header.append(headline);
    var card = $(document.createElement('div')).attr({
                                                            "id" : "collapse_"+dates.id, 
                                                            "class"    : "collapse",
                                                            "aria-labelledby"    : "heading_"+dates.id,
                                                            "data-parent"  : "#source-accordion"
                                                         });
        var cardbd = $(document.createElement('div')).attr("class","card-body");
            
        
        $.each(dates.data, function(ind, ele) {
            if(ele){
             $(cardbd).append("<div class='phraseRef' data-phraseref='"+ele.phraseId+"'><h6 class='sourcecit-header'>Relation: "+ele.citInfo+" &gt;&gt; <span class='chron-phraseLink' data-toRef='"+ele.phraseId+"'>"+ele.phraseId+"</span> </h6><p>"+ele.cit+"</p><hr/></div>")
            }
        });
        
       card.append(cardbd);

    $(parent).append(header);
    $(parent).append(card);
    return parent;
};



function createTargetList(dates){
    var parent = $(document.createElement('div')).attr("class","card sourceRef");
    var header = $(document.createElement('div')).attr({"class" : "card-header", "id" : dates.id});
        var title = dates.title ? dates.title : "<span style='color:red'>"+dates.id+"</span>";
        
        var headline = $(document.createElement('h5')).attr("class","mb-0");
        var button = $(document.createElement('div')).attr({
                                                            "class" : "sourceLinkHeader", 
                                                            "data-toggle"    : "collapse",
                                                            "data-target"    : "#collapse_"+dates.id,
                                                            "aria-expanded"  : "true",
                                                            "aria-controls"  : "collapse_"+dates.id
                                                         });
        $(button).html(title ? title : "<span style='color:red'>no title found</span>");
        headline.append(button);
        header.append(headline);
    var card = $(document.createElement('div')).attr({
                                                            "id" : "collapse_"+dates.id, 
                                                            "class"    : "collapse",
                                                            "aria-labelledby"    : "heading_"+dates.id,
                                                            "data-parent"  : "#target-accordion"
                                                         });
        var cardbd = $(document.createElement('div')).attr("class","card-body");
            
        
        $.each(dates.data, function(ind, ele) {
            if(ele){
             $(cardbd).append("<div class='phraseRef' data-phraseref='"+ele.toPhraseId+"'><h6 class='sourcecit-header'>Relation: "+ele.fromPhraseId+" &gt;&gt; <span class='chron-phraseLink' data-toRef='"+ele.toPhraseId+"'>"+ele.toPhraseId+"</span> </h6><p>There are xx relations</p><hr/></div>")
            }
        });
        
       card.append(cardbd);

    $(parent).append(header);
    $(parent).append(card);
    return parent;
};


function chron_loadSources(){
    //hide all sources
    $(".phraseRef").hide();
    $(".sourceRef").hide();
    //get id list for all page IDs
    //for all those IDs: show relations
    $("tei-item").each(function(){
        //console.log($(this).attr("id"));
        $("[data-phraseref='"  + $(this).attr("id")   +"']").closest("div.sourceRef").show();
        $("[data-phraseref='"  + $(this).attr("id")   +"']").show().parent(".sourceRef").show();
    });
};


const datesAreOnSameDay = (first, second) =>
    first.getFullYear() === second.getFullYear() &&
    first.getMonth() === second.getMonth() &&
    first.getDate() === second.getDate();
