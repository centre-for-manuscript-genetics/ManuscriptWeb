
                       
                                

/**
event listeners...
 */
$('body')



.on('click', '#newCollectionBtn', function () {
    var $el = $(this);
    //get entrypoint not from url parameter! url parameter might not be present due to url-mapping
    //var entryPoint = $el.data("resource");
    var entryPoint = $(this).data("resource");
    //TODO: what if no entryPoint is set? - should not be possible
    loadDoc("$app/modules/ajax-calls.xql?action=createCollection&entrypoint=" + entryPoint + cachedisable(), function (e) {
        var data = jQuery.parseJSON(e.responseText);
        if(data.success == "true"){
            loadContent("#content", "$app/templates/module-content.html?resource="+entryPoint);
        }
        //remove empty node garbage
        clean(document.body);
    });
})



.on('click', '#newDocumentBtn', function () {
    var $el = $(this);
    var entryPoint = $(this).data("resource");
    var settingsWindow = new LockedWindow("New Document");
    
    $(settingsWindow.content).load('$app/templates/new-document.html?entrypoint=' + entryPoint + cachedisable(), function() {
            var $resId = $('#docTitle').data('resourceid');
            //console.log($resId);
            initUploader($resId);
    });
    
    //settingsWindow.loadURL('$app/templates/new-document.html?entrypoint=' + entryPoint + cachedisable());
    
})
//when the new item button in a library is clicked.... request a new item and then request the edit-form for this item
.on('click', '#newBookBtn', function () {
    var $el = $(this);
    var entryPoint = $(this).data("resource");
    var settingsWindow = new LockedWindow("New Library Item");
    //request a new book, on success: request the book form with the corresponding id.
    loadDoc("$app/modules/ajax-calls.xql?action=newItem&entrypoint=" + entryPoint + cachedisable(), function (e) {
        var data = jQuery.parseJSON(e.responseText);
        if(data.success == "true"){
            //take new id from json response:
            var itemId = data.id;
            //request the book form and load it into the window
            $(settingsWindow.content).load('$app/templates/edit-book.html?itemid=' + itemId + cachedisable(), function() {
                var $resId = $('#docTitle').data('resourceid');
                initUploader($resId);
                
                //show type specific fields
                var resType= $("#recordType").val();
                console.log(resType);
                $('div[data-showon]').hide();
                $('[data-showon~="'+resType+'"]').show();
                
                
                //activate tagit on author field
                var sampleTags = ['Schäuble, Joshua Karl', 'Crowley, Ronan', 'Van Hulle, Dirk', "Dillen, Wout"];
                
                $('#field-author').tagit({
                    availableTags: sampleTags,
                    allowSpaces: true,
                    afterTagAdded: function(evt,ui){
                        console.log(ui.tagLabel);
                        //check if the added name is new
                        if(!sampleTags.includes(ui.tagLabel)){
                            settingsWindow.block();
                            var dialogueDiv = getNameDialogue(ui.tagLabel);
                            /*  $(dialogueDiv).dialog(
                                {appendTo: "#"+settingsWindow.getId()
                                }
                            );*/
                            
                            var personWindow = new LockedWindow("New Person");
                            personWindow.setContentHTML(dialogueDiv);
                            return false;
                        }
                        
                    }
                });
                
                
         
            });
        }
    });
})

//when a simple text field with the .form-simpletext class loses focus, contact server and ask it to change the elements text node
.on("blur",".form-simpletext",function(){

    var resourceId = $(this).closest("form").data('resourceid');
    var nodetype = $(this).data("nodetype");
    var newText = $(this).val();
    
    
    //validation stuff here:
    var valid = false;
    if(nodetype=="date"){
        if (/\d{4}/.test(newText)){valid = true;}
        else{ 
	       valid = false;
	       $(this).val('Please use yyyy format');
	    };
    } 
    else{valid = true;}
    
    
    if(valid){
        loadDoc("$app/modules/ajax-calls.xql?action=updateNodeText"   
                                                                   + "&resourceId=" + resourceId
                                                                   + "&nodeType="   + nodetype
                                                                   + "&newText="    + newText
                                                                   + cachedisable(), function (e) {
                 var resdata = jQuery.parseJSON(e.responseText);
                 if(resdata.success="true"){
                     $(this).val(resdata.value);
                     //alert(resdata.value);
                 }
        });
    }
    
    
})

.on("change",".form-select-simplevalue", function(){
    var resourceId = $(this).closest("form").data('resourceid');
    var nodetype = $(this).data("nodetype");
    var newText = $(this).val();
    loadDoc("$app/modules/ajax-calls.xql?action=updateNodeText"   
                                                                   + "&resourceId=" + resourceId
                                                                   + "&nodeType="   + nodetype
                                                                   + "&newText="    + newText
                                                                   + cachedisable(), function (e) {
                 var resdata = jQuery.parseJSON(e.responseText);
                 if(resdata.success="true"){
                    //if the "type" node was changed, show or hide regarding form fields
                    if(resdata.node="type"){
                        $('div[data-showon]').hide();
                        $('[data-showon~="'+newText+'"]').show();
                    }
                     //alert(resdata.value);
                     //todo: here I should handle what happens if a type requires other input fields!
                 }
        });
    
})

/* when a new module is selected */
.on('click', '.new-module', function () {
    //store what type of module to built
    var type = $(this).data("type");
    //inform RESTXQ to build/deploy the module
    loadDoc("$app/modules/ajax-calls.xql?action=createModule&type=" + type + cachedisable(), function (e) {
        var data = jQuery.parseJSON(e.responseText);
        if(data.success == "true"){
            loadContent("#content", "$app/templates/module-overview.html");
        }
        //remove empty node garbage
        clean(document.body);
    });
})
/*  when an editable-text is clicked, it is turned into a textarea so that the text can be edited, the changes are stored via restXQ on a jquery on() event */
/*  note: this works only when the editable text is somewhere within a div.resource-tile which holds a data-attribute with the resource id */
.on('click', '.editable-text', function () {
    var $el = $(this);
    var resId = $(this).data("resourceid");
    var $input = $('<textarea class="adminchange"/>').val($el.text().replace(/ +(?= )/g, '').trim());
    $el.replaceWith($input);
    //use autosize lib to autosize the textareas height nicely
    autosize(document.getElementsByClassName("adminchange"));
    $('.hyperlink-card').hide();
    
    var save = function () {
        var resourceId = $(this).closest("div.resource-tile").data('resourceid');  
        if(!resourceId){
            resourceId=resId;
        }
        var nodeType = $el.data('nodetype');
        var text = $input.val();
        loadDoc("$app/modules/ajax-calls.xql?action=updateNodeText&newText=" + text + "&resourceId=" + resourceId + "&nodeType=" + nodeType + cachedisable(), function (e) {
            var data = jQuery.parseJSON(e.responseText);            
            $el.text(data.value);
            $input.replaceWith($el);
            $('.hyperlink-card').show();
            if (nodeType == 'label') {
                loadDoc("$app/modules/ajax-calls.xql?action=getURLlabel&resourceId=" + resourceId + cachedisable(), function (d) {
                    var resdata = jQuery.parseJSON(d.responseText);
                    $el.parents("div.card.clickable").data("shownurl",resdata.urllabel);
                    //console.log($el.parents("div.card.clickable").data("shownurl"));
                    //$('#' + resourceId).attr("href", resdata.urllabel);
                });
            }
        });
    };
    $input.one('blur', save).focus();
})

/*  when an editable-tablecell is clicked, it is turned into a textarea so that the text can be edited, the changes are stored via restXQ on a jquery on() event */
/*  note: this works only when the editable text is somewhere within a div.resource-tile which holds a data-attribute with the resource id */
.on('click', '.editable-tablecell', function (e) {
    var $el = $(this);
    //unlikely to work here!
    var resId = $(this).data("resourceid");
    
    var entityId = $(this).parent('tr').data('id');
    var elementName = $(this).closest('table').find('th').eq( $(this).index()).data('elementname');
    console.log(entityId + "::" + elementName);
    
    
    var $input = $('<textarea class="adminchange"/>').val($el.text().replace(/ +(?= )/g, '').trim());
    $el.replaceWith($input);
    //use autosize lib to autosize the textareas height nicely
    autosize(document.getElementsByClassName("adminchange"));
    
    
    var save = function () {
        var resourceId = $(this).closest("div.resource-tile").data('resourceid');  
        if(!resourceId){
            resourceId=resId;
        }
        var nodeType = $el.data('nodetype');
        var text = $input.val();
        loadDoc("$app/modules/ajax-calls.xql?action=updateNodeText&newText=" + text + "&resourceId=" + resourceId + "&nodeType=" + nodeType + cachedisable(), function (e) {
            var data = jQuery.parseJSON(e.responseText);            
            $el.text(data.value);
            $input.replaceWith($el);
            $('.hyperlink-card').show();
            if (nodeType == 'label') {
                loadDoc("$app/modules/ajax-calls.xql?action=getURLlabel&resourceId=" + resourceId + cachedisable(), function (d) {
                    var resdata = jQuery.parseJSON(d.responseText);
                    $el.parents("div.card.clickable").data("shownurl",resdata.urllabel);
                });
            }
        });
    };
    $input.one('blur', save).focus();
})
  
    
.on('click', '.mod-delete', function () {
    var r = confirm("Are you sure you want to delete this module including all data contained? You cannot undo this later!");
    if (r == true) {
        var resourceId = $(this).closest("div.resource-tile").data('resourceid');
        loadDoc("$app/modules/ajax-calls.xql?action=deleteModule&resourceId=" + resourceId + cachedisable(), function (e) {
            var data = jQuery.parseJSON(e.responseText);
            //TODO: maybe add a nice fadeout?
            $("div[data-resourceid='"+data.id+"']").remove();
            //remove empty node garbage
            clean(document.body);
        });
    }})
    

.on('click', '.collection-delete', function () {
    var r = confirm("Are you sure you want to delete this collection including all data contained? You cannot undo this later!");
    if (r == true) {
        var resourceId = $(this).closest("div.resource-tile").data('resourceid');
        loadDoc("$app/modules/ajax-calls.xql?action=deleteCollection&resourceId=" + resourceId + cachedisable(), function (e) {
            var data = jQuery.parseJSON(e.responseText);
            //TODO: maybe add a nice fadeout?
            $("div[data-resourceid='"+data.id+"']").remove();
            //remove empty node garbage
            clean(document.body);
        });
    }
})


.on('click', '.mod-edit', function () {
    //alert("the share and access center is not implemented yet.");
    var settingsWindow = new LockedWindow("Settings Center");
    settingsWindow.loadURL('$app/templates/resourcesettings.html' + cachedisable());
    
    })



//when changes to a resource in the resource setting center are saved: send them to server and close locked window
.on('click', '.save-newDoc', function () {
    //TODO: send changes to server!
    //update the cardboard
    var entryPoint = $(this).data("entrypoint");
    console.log(entryPoint);
    closeLockedWindow();
    loadContent("#content","$app/templates/module-content.html?resource="+entryPoint);
})





.on('click', '.move-left', function () {
    var resourceId = $(this).closest("div.resource-tile").data('resourceid');
    var $el2move =  $(this).closest("div.resource-tile");
    
    loadDoc("$app/modules/ajax-calls.xql?action=moveNode&direction=left&resourceId=" + resourceId + cachedisable(), function (e) {
        //if response == true, turn the elements in the HTML representation as well
        var data = jQuery.parseJSON(e.responseText);
        if (data.success="true"){
            var animating = false;
            prevDiv = $el2move.prev('div.resource-tile'),
            distance = $el2move.offset().left - prevDiv.offset().left;
            if (! $el2move.is(":first-child")) {
                animating = true;
                //remove z-index class, elements are not "on top" for a nicer animation. these classes must be toggled back after the animation is complete
                $('.pull-to-top').toggleClass('temp-in-back').toggleClass('pull-to-top');
                $.when($el2move.animate({
                    left: - distance
                },
                500),
                prevDiv.animate({
                    left: distance
                },
                500)).done(function () {
                    prevDiv.css('left', '0px');
                    $el2move.css('left', '0px');
                    $el2move.insertBefore(prevDiv);
                    //if you want to reload all modules, this is the place to do it
                    $('.temp-in-back').toggleClass('pull-to-top').toggleClass('temp-in-back');
                    clean(document.body);
                    animating = false;
                    
                });
            }
        }
        
    });
})




.on('click', '.move-right', function () {
    var resourceId = $(this).closest("div.resource-tile").data('resourceid');
    var $el2move =  $(this).closest("div.resource-tile");

    loadDoc("$app/modules/ajax-calls.xql?action=moveNode&direction=right&resourceId=" +  resourceId + cachedisable(), function (e) {
        //if response == true, turn the elements in the HTML representation as well
        var data = jQuery.parseJSON(e.responseText);
        if (data.success="true"){
            var animating = false;
            folDiv = $el2move.next('div.resource-tile'),
            distance = $el2move.offset().left - folDiv.offset().left;
            if (! $el2move.is(":last-child")) {
                animating = true;
                //remove z-index class, elements are not "on top" for a nicer animation. the z-index will be back due to complete "replaceWith" later.
                $('.pull-to-top').toggleClass('temp-in-back').toggleClass('pull-to-top');
                $.when($el2move.animate({
                    left: - distance
                },
                500),
                folDiv.animate({
                    left: distance
                },
                500)).done(function () {
                    folDiv.css('left', '0px');
                    $el2move.css('left', '0px');
                    $el2move.insertAfter(folDiv);
                    //if you want to reload all modules, this is the place to do it
                     $('.temp-in-back').toggleClass('pull-to-top').toggleClass('temp-in-back');
                    clean(document.body);
                    animating = false;
                });
            }
        }
    });
})




.on('input', '#docTitle', function () {
    var camelURL = encodeURI(camelize($(this).val().trim()));
    var directory = $("#resourceURL").attr("placeholder").substr(0, $("#resourceURL").attr("placeholder").lastIndexOf("/"));
    $("#resourceURL").attr("placeholder", directory + "/" + camelURL);
    //alert($(this).val());
})


/* the next two listeners watch for changes of the color input on the settings page */
.on("input", ".css-var",function(e){
    /* todo: this bit might be put into a function --> also called within templates/settings-content.html */
    var root = document.documentElement;
    var cssVar = $(e.currentTarget).data('cssvar');
    console.log(cssVar);
    var newVal = e.currentTarget.value;
    console.log(newVal);
    root.style.setProperty("--"+cssVar, newVal);
})
.on("change", ".css-var", function(e){
    var cssVar = $(e.currentTarget).data('cssvar');
    var newVal = $(e.currentTarget).val();
    alert("only now the server should be contacted to update the color!");
    loadDoc("$app/modules/ajax-calls.xql?action=changeCSSvar&itemId="+cssVar+"&value="+encodeURIComponent(newVal), function (e) {
        var data = jQuery.parseJSON(e.responseText);
    });
})
;



/* initializes the fileuploader as done in TEIPublisher */
function initUploader($rootResourceId){
    'use strict';
    $('#fileupload').fileupload({
        url: "$app/modules/upload.xql",
        dataType: 'json',
        acceptFileTypes: /(\.|\/)(gif|jpe?g|png|xml|txt)$/i,
        formData: {
            "root": $rootResourceId
        },
        done: function (e, data) {
            //alert("done");
            $.each(data.result.files, function (index, file) {
                var tr = document.createElement("tr");
                var td = document.createElement("td");
                var link = document.createElement("a");
                link.href = file.path;
                link.target = "_blank";
                var icon = document.createElement("span");
                icon.className = "material-icons";
                icon.appendChild(document.createTextNode(file.name));
                link.appendChild(icon);
                td.appendChild(link);
                tr.appendChild(td);
                
                td = document.createElement("td");
                td.appendChild(document.createTextNode(file.path));
                tr.appendChild(td);
                
                $("#files").append(tr);
                if(file.foldertype =="transcripts"){
                    $(tr).clone().appendTo("#transcript-files");
                }else{
                    $(tr).clone().appendTo("#facsimile-files");
                }
                
            });
            //reloadDocTable();
        },
        processfail: function (e, data) {   
            //here I could potentially show the failed uploads?
            console.log('Processing ' + data.files[data.index].name + ' failed. Reason: ' + data.files[data.index].error);
            
        },
        progressall: function (e, data) {
            var progress = parseInt(data.loaded / data.total * 100, 10);
            $('#progress .progress-bar').css(
            'width',
            progress + '%');
        }
    }).on('fileuploadfail', function (e, data) {
        $.each(data.files, function (index) {
            alert('failed');
        });
    })
    .prop('disabled', ! $.support.fileInput).parent().addClass($.support.fileInput ? undefined: 'disabled');
    
   //make sure self-styled button triggers hidden input button 
   $('.fileinput-button').click(function(){
    
    $('#fileupload').click();
        });
}



/* random id's, here used to work around the cacheing function that would otherwise not call the actual URL but a cached version */
function cachedisable() {
    var S4 = function () {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    };
    return ("&" + S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "=" + S4() + S4() + S4());
}




/*
 * loadDoc() is used for assyncronous ajax calls, usally to RESTXQ. Note: loadDoc is also in manuscriptweb.js --> redundant!
 */
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

/* function removes empty text nodes and comments from a passed node */
function clean(node) {
    for (var n = 0; n < node.childNodes.length; n++) {
        var child = node.childNodes[n];
        if
        (
        child.nodeType === 8 ||
        (child.nodeType === 3 && ! /\S/.test(child.nodeValue))) {
            node.removeChild(child);
            n--;
        } else if (child.nodeType === 1) {
            clean(child);
        }
    }
}

function camelize (str) {
    return str.replace(/\W+(.)/g, function (match, chr) {
        return chr.toUpperCase();
    });
}


function getNameDialogue(nameString){
    var firstname, lastname;
    if(nameString.indexOf(',') > -1){
        splitme = nameString.split(",",1);
        firstname= splitme[1].replace(",","");
        lastname = splitme[0];
    }
    else if(nameString.indexOf(' ') > -1){
        splitme = nameString.split(" ",1)
        firstname = splitme[0];
        lastname = splitme[1];
    }
    else{
        lastname = nameString;
    }
    /* TODO: this should go into a template on the server! */
    var divString = '<div title="New Person" class="windowcont-wrapper">\
                        <div class="windowcont-content">\
                            <div class="form-group row col-sm-12">\
                                <p>Is this data correct?</p> \
                            </div>\
                            <div class="form-group row col-sm-12">\
                                <label for="field-title" class="col-sm-3 col-form-label">Firstname(s):</label>\
                                <div class="col-sm-9">\
                                    <input type="text" value="'+firstname+'" class="form-control-plaintext form-input form-simpletext" id="field-title" data-nodetype="title"/>\
                                </div>\
                            </div>\
                            <div class="form-group row col-sm-12">\
                                <label for="field-title" class="col-sm-3 col-form-label">Lastname(s):</label>\
                                <div class="col-sm-9">\
                                    <input type="text" value="'+lastname+'" class="form-control-plaintext form-input form-simpletext" id="field-title" data-nodetype="title"/>\
                                </div>\
                            </div>\
                        </div>\
                        <footer class="windowcont-footer">\
                            <div class="text-center">\
                                <button class="btn btn-mw-outline my-2 save-newPerson">\
                                    <i class="far fa-save"/> Save\
                                </button>\
                            </div>\
                         </footer>\
                     </div>';
    var div = $(divString);
    return div;
    
}