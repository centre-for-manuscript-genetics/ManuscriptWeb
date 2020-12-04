
var lastMovedId;


//constructor for new Digger
function Digger (diggerId) {
    diggers.push(diggerId);
    this.diggerId = diggerId;
    this.facsimileId = diggerId.replace("dig_", "");
    this.lastMovedId;
    this.svgCanvas = document.querySelector('#' + diggerId),
    this.svgNS = 'http://www.w3.org/2000/svg',
    this.xhtmlNS = 'http://www.w3.org/1999/xhtml';
    this.rectangles =[];
    this.TEIcontents;
    
    this.builtResizeSlider();
    
    //global vars for the image & its' scaling
    this.origHeight = $(this.svgCanvas).find('image').attr('height');
    this.origWidth = $(this.svgCanvas).find('image').attr('width');
    
    this.scalingFactor = 1.0;
    
    this.getZones();
}

Digger.prototype.getZones = function () {
    var tempThis = this;
    loadDoc("$app/modules/ajax-calls.xql?action=getFacZones&resourceId=" + this.facsimileId , function (e) {
            var obj = jQuery.parseJSON(e.responseText);
            $.each(obj.data, function(i,val){
                var myDiv = $.parseHTML( val.text);
                //console.log(myDiv);
                var rect = new Rectangle (tempThis, parseFloat(val.x), parseFloat(val.y), parseFloat(val.width), parseFloat(val.height), this.svgCanvas, this.diggerId + "_jstree", myDiv, parseFloat(val.rotate));
            }); 
        });
};

Digger.prototype.builtResizeSlider = function () {
    var sliderDiv = document.createElement('div');
    sliderDiv.classList.add('btn-group');
    sliderDiv.classList.add('btn-group-s');
    
    sliderDiv.classList.add('resizeButtons');
    sliderDiv.setAttribute('role', "group");
    sliderDiv.setAttribute('aria-label', "...");
    var myInput = document.createElement('input');
    myInput.classList.add('resizeSlider');
    myInput.setAttribute("type", "range");
    myInput.setAttribute("min", "0.05");
    myInput.setAttribute("max", "1");
    myInput.setAttribute("step", "0.01");
    myInput.setAttribute("value", "1");
    sliderDiv.appendChild(myInput);
    
    this.scaler = myInput;
    
    myInput.addEventListener('input', this.scaleCanvas.bind(this), false);
    //todo: i don't like this positioning of the slider. should not be parent depending!
    $(this.svgCanvas).parent().parent().before(sliderDiv);
};

Digger.prototype.scaleCanvas = function () {
    var tempthis = this;
    this.scalingFactor = tempthis.scaler.value;
    this.setSvgScale();
};

Digger.prototype.setSvgScale = function () {
    
    $(this.svgCanvas).attr("width", this.scalingFactor * this.origWidth);
    $(this.svgCanvas).attr("height", this.scalingFactor * this.origHeight);
    $(this.svgCanvas).find('g.scalingParent').attr("transform", "scale(" + this.scalingFactor + ")");
}

$(document).ready(function () {
    //the array $digger must be initialized globally in page.html//mw.js! otherwise this here wont work!
    $(".digger").each(function () {
        var myId = $(this).attr('id');
        console.log("id:"+myId+ "; index: "+ diggers.indexOf(myId));
        if (diggers.indexOf(myId) == -1) {
            var thisDigger = new Digger(myId);
            //todo: calculate the default scaling factor based on image size and window size
            thisDigger.scalingFactor = "0.2";
            thisDigger.scaler.value = "0.2";
            thisDigger.setSvgScale();
            
        }
    });
    
});



//constructor for a new rectangle. x/y is its Startpoint, w and h its dimension, svgCanvas the SVG-node to add it to, myId is its Id.
function Rectangle (digger, x, y, w, h, svgCanvas, myId, myText, rotationAngle) {
    this.digger = digger;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.myId = myId.replace('_jstree', '_rect');
    this.myangle = 0;
    this.stroke = 2;
    this.rotAngle = rotationAngle;
    
    
    //a rectangle is not just a svg:rect but a svg:g with a svg:rect and a svg:text nested into it.
    this.el = document.createElementNS(digger.svgNS, 'rect');
    this.el.setAttribute('data-index', digger.rectangles.length);
    
    
    this.transcript = document.createElementNS(digger.svgNS, 'foreignObject');
    $(this.transcript).attr('x',x).attr('y',y).attr('width',w).attr('height',h);
    
    this.scalingcont = document.createElement('div');
    $(this.scalingcont).attr('xmlns','http://www.w3.org/1999/xhtml');
    $(this.scalingcont).addClass('zoneTranscript').width(parseInt(w)).height(parseInt(h));
    
    //$(myText).attr('xmlns','http://www.w3.org/1999/xhtml');
    //$(myText).addClass('zoneTranscript').width(parseInt(w)).height(parseInt(h));

    $(this.scalingcont).append(myText);
    
    $(this.transcript).append(this.scalingcont);

    
    this.myg = document.createElementNS(digger.svgNS, 'g');
    this.myg.setAttribute('class', 'hidden-rectangle');
    this.myg.setAttribute('transform', 'rotate(' + rotationAngle + ',' + x + ',' + y + ')');
    
    this.myg.appendChild(this.transcript);
    this.myg.appendChild(this.el);
    
    digger.rectangles.push(this);
    
    this.draw();
    digger.svgCanvas.getElementById('scalingParent').appendChild(this.myg);
    //this.scaleFont();
    
    $(this.scalingcont).textfill({
                        'innerTag'        : 'div',
                        'changeLineHeight':true,
                        'minFontPixels':20,
                        'maxFontPixels':120,
                         success: function() {
		                          //nothing
		                          },
		                 fail: function() {
		                          console.log("font scaling failed!")
		                  }
                        });
        
}

//draws the rectangle, should always be called before "scaleFont()", because the BBox in scaleFont() is only available after the rectangle has been placed on the SVG
Rectangle.prototype.draw = function () {
    this.myg.setAttribute('transform', 'rotate(' + this.rotAngle + ',' + this.x + ',' + this.y + ')');
    
    this.el.setAttribute('x', this.x);
    this.el.setAttribute('y', this.y);
    this.el.setAttribute('width', this.w);
    this.el.setAttribute('height', this.h);
    this.el.setAttribute('stroke-width', this.stroke);
    this.el.setAttribute('rx', 5);
    this.el.setAttribute('ry', 5);
   // this.transcript.setAttribute('x', 0);

   // this.transcript.setAttribute('y', -2.5);

    
    //set the rectangle active if it has already been appended (otherwise its the first draw)
    if (document.getElementById(this.myId)) {
       // setActive(this.myId.replace('_rect', ''));
    }
    

    
}

//scales the font roughly into the rectangle,
//TODO:this function needs further development
Rectangle.prototype.scaleFont = function () {
    var testDiv = $(this.transcript).find('div').clone();
    $(testDiv).css({
                        'width' : 'auto',
                        'height' : 'auto'})
    var height = this.h;
    
    var i = 14;
    var find =12;
    while(i<16){
        $(this.transcript).css({'font-size' : i}); 
        console.log("(thisH:"+this.h+"- thisW:"+this.w+") font: "+ i+ "--- W: "+ testDiv.width() + "--- h: "+testDiv.height());
        i+=1;
    }
    
    
    /* /
    var bb = textNode.getBBox();
    var widthTransform = this.w / (1.1 * bb.width);
    var heightTransform = this.h / (1.1 * bb.height);
    var value = widthTransform < heightTransform ? widthTransform: heightTransform;
    

    var vertX = this.x +(3 * this.stroke);
    var vertY = this.y + this.h -(3 * this.stroke);
    if (this.transcript.textContent != "") {
        this.transcript.setAttribute("transform", "matrix(" + value + ", 0, 0, " + value + ", " + vertX + "," + vertY + ")");
    }*/
}


//sets the active element in the tree and on the svg
function setActive(idToSet) {
    console.log(idToSet);
    if (isLocked(idToSet + "_rect")) {
        $("#range-slider1").attr('disabled', 'true');
    } else {
        $("#range-slider1").removeAttr('disabled');
    }
    
    activateRectangle(idToSet);
}


/*function to find closest ancestor of given selector, taken from stackoverflow*/
function closestAncestor(el, selector) {
    var matchesFn;
    // find vendor prefix
    [ 'matches', 'webkitMatchesSelector', 'mozMatchesSelector', 'msMatchesSelector', 'oMatchesSelector'].some(function (fn) {
        if (typeof document.body[fn] == 'function') {
            matchesFn = fn;
            return true;
        }
        return false;
    })
    // traverse parents
    while (el !== null) {
        parent = el.parentElement;
        if (parent !== null && parent[matchesFn](selector)) {
            return parent;
        }
        el = parent;
    }
    return null;
}


/*function activates a rectangle on the svg canvas*/
function activateRectangle(idToSet) {
    var idWithRect = idToSet + '_rect';
    if (document.getElementById(idWithRect)) {
        if (document.getElementById(lastMovedId)) {
            //if the last active rectangle is locked, only remove active-rectangle, but keep it locked...
            if (isLocked(lastMovedId)) {
                document.getElementById(lastMovedId).getElementsByTagName('rect')[0].setAttributeNS(null, 'class', 'locked-rectangle');
                //...else remove active-rectangle but keep it and unlocked "edit-rectangle"
            } else {
                document.getElementById(lastMovedId).getElementsByTagName('rect')[0].setAttributeNS(null, 'class', 'edit-rectangle');
            }
        }
        //set "lastMovedId" to the new rectangle - if it is new. Contact server about old one
        if (lastMovedId == idWithRect) {
            console.log("old");
        } else {
            if (lastMovedId) {
                sendToServer(lastMovedId.replace('_rect', ''));
            }
            lastMovedId = idWithRect;
        }
        if (isLocked(lastMovedId)) {
            document.getElementById(idWithRect).getElementsByTagName('rect')[0].setAttribute('class', 'active-rectangle locked-rectangle');
        } else {
            document.getElementById(idWithRect).getElementsByTagName('rect')[0].setAttribute('class', 'active-rectangle edit-rectangle');
        }
    }
}

function sendToServer(idToSend) {
    var curRec = document.getElementById(idToSend + '_rect').getElementsByTagName('rect')[0];
    var x = $(curRec).attr('x');
    var y = $(curRec).attr('y');
    var height = $(curRec).attr('height');
    var width = $(curRec).attr('width');
    var rotate = getRotationFromTransform(idToSend + '_rect');
    var resId = document.getElementById(idToSend).dataset.resid;
    //console.log(resId);
    loadDoc("$app/modules/ajax-calls.xql?action=storeFacsZone&resourceId=" + resId + "&elementId=" + idToSend + "&x=" + x + "&y=" + y + "&width=" + width + "&height=" + height + "&rotate=" + rotate, function (e) {
        console.log(e.responseText);
    });
}


/*function to deactivate the currently activated rectangle (if any)*/
function deactivateRectangle() {
    var temp = document.getElementById(lastMovedId).getElementsByTagName('rect')[0].getAttribute('class').replace('active-rectangle', '');
    document.getElementById(lastMovedId).getElementsByTagName('rect')[0].setAttribute('class', temp);
}





/*Function to set the text of a rectangle (change)*/
function setRectText(anchorId, newText) {
    var recId = anchorId.replace('_jstree', '_rect');
    $('#' + recId + '>text').text(newText);
    var result = $.grep(rectangles, function (e) {
        return e.myId == recId;
    });
    result[0].scaleFont();
}



/*Function to get the text of a rectangle*/
function getRectText(anchorId) {
    var rectId = anchorId.replace('_jstree', '_rect');
    var teiId = anchorId.replace('_jstree', '');
    var testText = $('#' + rectId).text();
    return (testText);
}

/*sets the text-node of the given ID to the given text*/
function setTeiText(elemId, newtext) {
    $(teiDoc.getElementById(elemId.replace('_jstree', ''))).text(newtext);
}

/*gets the text under a given TEI element id*/
function getTeiText(treeId) {
    return $(teiDoc.getElementById(treeId.replace('_jstree', ''))).text();
}


/*if image is selected (in case there was none found in the TEI-file or file system) this image is drawn on the screen. TODO: adjust image and SVG dimensions!*/
function addImageToSVG(event) {
    var selectedFile = event.target.files[0];
    var reader = new FileReader();
    
    var svgtag = document.getElementById("myCanvas");
    //everything that has to be processed after the file has been loaded goes into here:
    reader.onload = function (event) {
        var image = new Image();
        image.src = event.target.result;
        image.onload = function () {
            //put image on screen
            //set image size, question: should this size be taken from the TEI or from the image? scaling?
            //$(svgtag).attr("viewBox","0 0 "+this.width +" "+this.height);
            $(svgtag).attr({
                width: this.width, height: this.height
            });
            var imLink = image.src;
            var svgimg = document.createElementNS(svgNS, 'image');
            svgimg.setAttributeNS(null, 'height', this.height);
            svgimg.setAttributeNS(null, 'width', this.width);
            svgimg.setAttributeNS('http://www.w3.org/1999/xlink', 'href', image.src);
            svgimg.setAttributeNS(null, 'x', '0');
            svgimg.setAttributeNS(null, 'y', '0');
            svgimg.setAttributeNS(null, 'visibility', 'visible');
            svgCanvas.getElementById('scalingParent').appendChild(svgimg);
            //set global origHeight and origSize for Scaling Functions
            origHeight = this.height;
            origWidth = this.width;
        }
    };
    
    reader.readAsDataURL(selectedFile);
}


function processImageFile(event) {
    var selectedFile = event.target.files[0];
    var reader = new FileReader();
    
    var svgtag = document.getElementById("myCanvas");
    //everything that has to be processed after the file has been loaded goes into here:
    reader.onload = function (event) {
        $('#editContainer').css('display', 'inline');
        var image = new Image();
        image.src = event.target.result;
        image.onload = function () {
            //put image on screen
            //set image size, question: should this size be taken from the TEI or from the image? scaling?
            //$(svgtag).attr("viewBox","0 0 "+this.width +" "+this.height);
            $(svgtag).attr({
                width: this.width, height: this.height
            });
            
            //set global origHeight and origSize for Scaling Functions
            origHeight = this.height;
            origWidth = this.width;
            
            placeTEIrects();
        }
    };
    reader.readAsDataURL(selectedFile);
}


//updates the coordinates of a zone in the TEI after it was changed on the SVG
function updateTEIcoordinates(passedId) {
    var zoneId = passedId + '_rect';
    var ulx = parseInt($('#' + zoneId).find('rect').attr("x")),
    uly = parseInt($('#' + zoneId).find('rect').attr("y")),
    lrx = ulx + parseInt($('#' + zoneId).find('rect').attr("width")),
    lry = uly + parseInt($('#' + zoneId).find('rect').attr("height"));
    
    $(teiDoc).find('#' + passedId).attr({
        'ulx': ulx,
        'uly': uly,
        'lrx': lrx,
        'lry': lry
    });
    
    //if its a zone, also update the @rotate attribute!
    if (passedId.indexOf('zone') > -1) {
        var result = $.grep(rectangles, function (e) {
            return e.myId == zoneId;
        });
        $(teiDoc).find('#' + passedId).attr({
            'rotate': result[0].rotAngle
        });
    }
}



function getRotationFromTransform(rectId) {
    var curRec = document.getElementById(rectId);
    var transform = $(curRec).attr('transform');
    var rotate = transform.split('(')[1].split(',')[0];
    return rotate;
}

//places all tei:zones that already have coordinates given onto the SVG
function placeTEIrects() {
    $(TEIcontents).find('zone').each(function () {
        if ($(this).attr("ulx") && $(this).attr("uly") && $(this).attr("lrx") && $(this).attr("lry")) {
            var myX = parseInt($(this).attr("ulx"));
            var myY = parseInt($(this).attr("uly"));
            
            var myId = $(this).attr("id");
            
            var myheight = parseInt($(this).attr("lry")) - myY;
            var mywidth = parseInt($(this).attr("lrx")) - myX;
            
            //if zone has a rotation attribute set them
            var rotAngle = parseInt(ghf0);
            if ($(this).attr('rotation')) {
                rotAngle = parseInt($(this).attr('rotation'));
            }
            
            var myText = $(this).text();
            if (myText != "") {
                new Rectangle(myX, myY, mywidth, myheight, svgCanvas, myId, myText, rotAngle);
            }
        }
    });
}


/*Function to delete a selected Element from TEI, SVG, jsTree and rectangles[] */
function deleteSelected(evt) {
    var selectedA = $("#html1").jstree().get_selected();
    var superId = selectedA[0].replace('_jstree', '');
    if (superId.indexOf('line') > -1 ||
    superId.indexOf('surface') > -1 ||
    superId.indexOf('zone') > -1 ||
    superId.indexOf('del') > -1 ||
    superId.indexOf('add') > -1 ||
    superId.indexOf('surfaceGrp') > -1) {
        var r = confirm("Are you sure you want to delete this element and all its children?");
        if (r == true) {
            //remove from jstree
            $('#html1').jstree("delete_node", selectedA[0]);
            //remove element and all its children from SVG Canvas
            var allChildren = Array.prototype.slice.call(teiDoc.getElementById(superId).querySelectorAll("*"), 0);
            allChildren.forEach(function (myEl) {
                $('#' + myEl.id + '_rect').remove();
            });
            $('#' + superId + '_rect').remove();
            //remove from TEI file
            $(teiDoc).find('#' + superId).remove();
            //TODO: remove from rectangles[]
            //TODO: select parent or other element
        }
    } else {
        alert("This element can't be deleted!");
    }
}

/*locks or unlocks a rectangle on the svg canvas*/
function toggleElementLocker() {
    var superId = lastMovedId;
    if (document.getElementById(superId)) {
        if (isLocked(superId)) {
            document.getElementById(superId).getElementsByTagName('rect')[0].setAttributeNS(null, 'class', 'active-rectangle edit-rectangle');
        } else {
            document.getElementById(superId).getElementsByTagName('rect')[0].setAttributeNS(null, 'class', 'locked-rectangle');
        }
    }
    if (isLocked(superId)) {
        $("#range-slider1").attr('disabled', 'true');
    } else {
        $("#range-slider1").removeAttr('disabled');
    }
}


//checks if a rectangle on the svg canvas is marked as locked
function isLocked(myid) {
    if (document.getElementById(myid) && document.getElementById(myid).getElementsByTagName('rect')[0].getAttributeNS(null, 'class')) {
        return (document.getElementById(myid).getElementsByTagName('rect')[0].getAttributeNS(null, 'class').indexOf('locked-rectangle') > -1)
    } else {
        return (false);
    }
}

/*function to be called when a new TEI file has been selected. Calls functions to check the TEI file and (in case its valid for our needs) processes it)*/
function processTEIfile(evt) {
    //Retrieve the first (and only!) File from the FileList object
    var f = evt.target.files[0];
    
    if (f) {
        var r = new FileReader();
        
        //everything that has to be processed after the file has been loaded goes into here:
        r.onload = function (e) {
            TEIcontents = e.target.result;
            var xmlDoc = $.parseXML(TEIcontents);
            var TEIparsed = $(xmlDoc);
            //if root element is TEI, to be replaced by if "isUsableTEI(xmlDoc)", TODO: write "isUsableTEI()"
            if (xmlDoc.documentElement.tagName == 'TEI') {
                //TODO: check if image-links (one or more!) are given in the TEI, if so, check if image can be found on filesystem (can only be loaded on server system)
                $('#teiSelection').css("display", 'none');
                $('#imageSelection').css('display', 'inline');
                var link = TEIparsed.find('graphic').attr("url");
            } else {
                alert("This is not a TEI File. Please select another file." + xmlDoc.documentElement.tagName);
            }
        }
        r.readAsText(f);
    } else {
        alert("Failed to load file");
    }
}


//adds the CSS information to style the rectangles to the SVG file
function addCSStoSVG() {
    var defsElement = document.createElementNS(svgNS, 'defs'),
    styleElement = document.createElementNS(svgNS, 'style');
    styleElement.setAttribute('type', 'text/css');
    styleElement.innerHTML = "rect{fill:grey;fill-opacity: 0.2;stroke:#8AC007;stroke-opacity:1;}";
    defsElement.appendChild(styleElement);
    svgCanvas.insertBefore(defsElement, svgCanvas.firstChild);
}


/*function to download the svg file at any point. The same function could probably be used to download the TEI file at any stage. TODO: adjust it by using parameters!*/
/*TODO: function is not called tested in this betaversion, adjust it! (taken from previous experiments)*/
function onSVGdownload() {
    addCSStoSVG();
    imageScale(0);
    var textToWrite = new XMLSerializer().serializeToString(svgCanvas);
    var textFileAsBlob = new Blob([textToWrite], {
        type: 'text/plain'
    });
    var fileNameToSaveAs = 'output.svg'//Your filename;
    
    var downloadLink = document.createElement("a");
    downloadLink.download = fileNameToSaveAs;
    downloadLink.innerHTML = "Download File";
    
    // Firefox requires the link to be added to the DOM
    // before it can be clicked.
    downloadLink.href = window.URL.createObjectURL(textFileAsBlob);
    //downloadLink.onclick = destroyClickedElement;
    downloadLink.style.display = "none";
    document.body.appendChild(downloadLink);
    
    downloadLink.click();
}


function onTEIdownload() {
    var serializer = new XMLSerializer();
    
    //jQuery.merge() for deep copy! otherwise ids are removed in working instance as well
    var parsetotext = serializer.serializeToString(teiDoc);
    //remove id via regex and add linebreak between elements
    var out = parsetotext.replace(/ id="[^"]*"/g, '').replace(/></g, ">\n<");
    
    var textFileAsBlob = new Blob([out], {
        type: 'text/xml'
    });
    var fileNameToSaveAs = 'output.xml';
    
    var downloadLink = document.createElement("a");
    downloadLink.download = fileNameToSaveAs;
    downloadLink.innerHTML = "Download File";
    
    // Firefox requires the link to be added to the DOM
    // before it can be clicked.
    downloadLink.href = window.URL.createObjectURL(textFileAsBlob);
    //downloadLink.onclick = destroyClickedElement;
    downloadLink.style.display = "none";
    document.body.appendChild(downloadLink);
    
    downloadLink.click();
}




var teiDoc = document.implementation.createDocument("http://www.tei-c.org/ns/1.0", "TEI", null);


function addTeiElement(elementName, parentId, lastOrAfter, elId) {
    //if no elId is given a unique one is produced
    if (elId === undefined || elId == '') {
        //the uniqueId for change elements is shorter (because they're part of the actual TEI)
        if (elementName == "change") {
            var realId = elementName + '_' + shortGuid();
        } else {
            var realId = elementName + '_' + guid();
        }
    } else {
        var realId = elId;
    }
    var jsTreeId = realId + '_jstree';
    var teiElement = createTeiElement(elementName, realId);
    
    //if no parentId is given, the element is added to the root element
    if (parentId == "" || parentId === undefined || parentId == null) {
        teiDoc.documentElement.appendChild(teiElement);
        $("#html1").jstree('create_node', 'tei_jstree', {
            id: jsTreeId, text: "&lt;" + elementName + "&gt;"
        },
        'last');
        //else the element is added to the given parentId (either last inside oder "after" as a sibbling)
    } else {
        $("#html1").jstree('create_node', parentId + '_jstree', {
            id: jsTreeId, text: "&lt;" + elementName + "&gt;"
        },
        lastOrAfter);
        if (lastOrAfter == "last") {
            teiDoc.getElementById(parentId).appendChild(teiElement);
        } else {
            teiDoc.getElementById(parentId).parentNode.insertBefore(teiElement, teiDoc.getElementById(parentId).nextSibling);
        }
    }
    //whenever a listChange is produced, it also gets a change child, listChange without children is not valid...
    //TODO: maybe change that... in other instances it cannot be prohibited, that users produce invalid tei either
    if (elementName == "listChange") {
        addTeiElement('change', realId, 'last', '');
    }
}



function createTeiElement(elName, elfId) {
    var myElement = document.createElementNS('http://www.tei-c.org/ns/1.0', elName);
    if (elfId) {
        myElement.setAttribute('id', elfId);
        //change elements get a xml:id as default (otherwise they can't be linked to)
        if (elName == "change") {
            myElement.setAttribute('xml:id', elfId);
        }
    }
    return (myElement);
}



function createDefaultJstree() {
    $("#html1").jstree('create_node', '#', {
        id: 'tei_jstree', text: "&lt;TEI&gt;"
    },
    'inside');
    addTeiElement('teiHeader', '', 'last', 'teiHeader');
    addTeiElement('fileDesc', 'teiHeader', 'last', 'fileDesc');
    addTeiElement('titleStmt', 'fileDesc', 'last', 'titleStmt');
    addTeiElement('title', 'titleStmt', 'last', 'title_1');
    addTeiElement('publicationStmt', 'fileDesc', 'last', 'publicationStmt');
    addTeiElement('p', 'publicationStmt', 'last', '');
    addTeiElement('sourceDesc', 'fileDesc', 'last', 'sourceDesc');
    addTeiElement('p', 'sourceDesc', 'last', '');
    addTeiElement('sourceDoc', '', 'last', 'sourceDoc_1');
    
    
    $("#html1").on('select_node.jstree', function (e, data) {
        var selectedA = $("#html1").jstree().get_selected();
        showElementOptions(selectedA);
        /*when node is selected, but there is no corresponding rectangle, the last activated rectangle get deactivated, otherwise the corresponding rectangle will be activated*/
        if (document.getElementById(selectedA[0].replace('_jstree', '_rect'))) {
            activateRectangle(selectedA[0].replace('_jstree', ''));
        } else if (document.getElementById(lastMovedId)) {
            deactivateRectangle();
        }
        if (selectedA[0].indexOf('zone') > -1) {
            $('#rotation_area').show();
        } else {
            $('#rotation_area').hide();
        }
    }).jstree();
}


function showElementOptions(treeId) {
    $('.optionIcons').remove();
    var fullId = treeId[0];
    var positionString = (fullId + '_anchor');
    //TODO: maybe the elementName should not be retrieved via id conventions?
    var teiElementName = fullId.split('_')[0];
    var allowedInside =[], allowedAfter =[], allowedAttributes =[];
    if (teiElementName == 'sourceDoc') {
        allowedInside =[ 'graphic', 'surface', 'surfaceGrp'];
        //allowedAfter =['sourceDoc','text'];
    } else if (teiElementName == 'surface') {
        allowedInside =[ 'zone', 'line', 'graphic', 'surface', 'surfaceGrp'];
        allowedAfter =[ 'surface', 'surfaceGrp'];
    } else if (teiElementName == 'surfaceGrp') {
        allowedInside =[ 'surface', 'surfaceGrp'];
        allowedAfter =[ 'surface', 'surfaceGrp'];
    } else if (teiElementName == "zone") {
        allowedInside =[ 'line', 'zone', 'graphic', 'surface', 'add', 'del'];
        allowedAfter =[ 'line', 'zone', 'graphic', 'surface'];
    } else if (teiElementName == "line") {
        allowedInside =[ 'line', 'zone', 'add', 'del'];
        allowedAfter =[ 'line', 'zone', 'graphic', 'surface'];
    } else if (teiElementName == "creation") {
        allowedInside =[ 'listChange'];
    } else if (teiElementName == "listChange") {
        allowedInside =[ 'listChange', 'change'];
        allowedAfter =[ 'listChange'];
    } else if (teiElementName == "change") {
        allowedAfter =[ 'listChange', 'change'];
    }
    
    var buttonGroup = makeButtons(fullId, allowedInside, allowedAfter);
    $(document.getElementById(positionString)).after(buttonGroup);
}

function makeButtons(elId, allowedInside, allowedAfter) {
    var parentDiv = document.createElement("div");
    $(parentDiv).attr({
        "class": "btn-group optionIcons",
        "role": "group",
        "aria-label": "...",
        "style": "display: inline; margin-left: 5px"
    });
    
    //p and title elements get a textfield, but are not in any way connected to the canvas
    if (elId.indexOf('p_') == 0 || elId.indexOf('title_') == 0 || elId.indexOf('change_') == 0) {
        var oldtext = getTeiText(elId);
        var myInput = document.createElement("input");
        $(myInput).attr({
            "type": "text",
            "value": oldtext,
            "class": "text-input"
        });
        parentDiv.appendChild(myInput);
        $(myInput).keyup(function () {
            //update Text on TEI in background
            setTeiText(elId, $(myInput).val());
        });
    }
    //If its a zone or a line: add the textfield for Transcript
    if ((elId.indexOf('zone') > -1) || (elId.indexOf('line') > -1)) {
        var oldtext = getRectText(elId);
        var myInput = document.createElement("input");
        $(myInput).attr({
            "type": "text",
            "value": oldtext,
            "class": "text-input"
        });
        parentDiv.appendChild(myInput);
        $(myInput).keyup(function () {
            //update Text on rectangle and on TEI in background
            setRectText(elId, $(myInput).val());
            setTeiText(elId, $(myInput).val());
        });
    }
    
    /*Add Inside Button*/
    if (allowedInside.length > 0) {
        var myDiv = document.createElement("div");
        $(myDiv).attr({
            "class": "dropdown",
            "style": "display: inline; margin-left: 5px"
        });
        var myButton = document.createElement("button");
        $(myButton).attr({
            "class": "btn btn-default btn-xs dropdown-toggle",
            "type": "button",
            "id": "btn_allowedInside",
            "data-toggle": "dropdown",
            "aria-haspopup": "true",
            "aria-expanded": "false"
        });
        var t = document.createTextNode("add Inside");
        var myCaret = document.createElement("span");
        $(myCaret).attr("class", "caret");
        myButton.appendChild(t);
        myButton.appendChild(myCaret);
        myDiv.appendChild(myButton);
        var myUl = document.createElement("ul");
        $(myUl).attr({
            "class": "dropdown-menu",
            "aria-labelledby": "btn_allowedInside"
        });
        for (item in allowedInside) {
            var myLi = document.createElement("li");
            var myLink = document.createElement("a");
            $(myLink).attr({
                "href": "#",
                "onClick": "generateNode('last','" + elId + "','" + allowedInside[item] + "')"
            });
            myLink.appendChild(document.createTextNode(allowedInside[item]));
            myLi.appendChild(myLink);
            myUl.appendChild(myLi);
        }
        myDiv.appendChild(myUl);
        parentDiv.appendChild(myDiv);
    }
    /*Add After Button*/
    if (allowedAfter.length > 0) {
        var myDiv2 = document.createElement("div");
        $(myDiv2).attr({
            "class": "dropdown",
            "style": "display: inline; margin-left: 5px"
        });
        var myButton2 = document.createElement("button");
        $(myButton2).attr({
            "class": "btn btn-default btn-xs dropdown-toggle",
            "type": "button",
            "id": "btn_allowedAfter",
            "data-toggle": "dropdown",
            "aria-haspopup": "true",
            "aria-expanded": "false"
        });
        var t2 = document.createTextNode("add After");
        var myCaret2 = document.createElement("span");
        $(myCaret2).attr("class", "caret");
        myButton2.appendChild(t2);
        myButton2.appendChild(myCaret2);
        myDiv2.appendChild(myButton2);
        var myUl2 = document.createElement("ul");
        $(myUl2).attr({
            "class": "dropdown-menu",
            "aria-labelledby": "btn_allowedAfter"
        });
        for (item2 in allowedAfter) {
            var myLi2 = document.createElement("li");
            var myLink2 = document.createElement("a");
            $(myLink2).attr({
                "href": "#",
                "onClick": "generateNode('after','" + elId + "','" + allowedAfter[item2] + "')"
            });
            myLink2.appendChild(document.createTextNode(allowedAfter[item2]));
            myLi2.appendChild(myLink2);
            myUl2.appendChild(myLi2);
        }
        myDiv2.appendChild(myUl2);
        parentDiv.appendChild(myDiv2);
    }
    return (parentDiv);
}

function generateNode(where, parentNodeId, nodeType) {
    if (nodeType == "change") {
        var teiId = nodeType + '_' + shortGuid();
    } else {
        var teiId = nodeType + '_' + guid();
    }
    var parentTeiNodeId = parentNodeId.replace('_jstree', '');
    var rectId = teiId + '_jstree';
    addTeiElement(nodeType, parentTeiNodeId, where, teiId);
    
    if (nodeType == 'surface' | nodeType == 'zone' | nodeType == 'line') {
        //here the default dimensions have to be adjusted and selected smarter
        var defaultWidth = 400;
        var defaultHeight = 150;
        if (origWidth > 100) {
            defaultWidth = 0.5 * origWidth;
        }
        //mark startposition depend on scrolling?
        var startX = 0.1 * $('#svg_area').width();
        var startY = (topScroll / scalingFactor) +($('#svg_area').height() / 2);
        new Rectangle (startX, startY, defaultWidth, 100, svgCanvas, rectId, nodeType, 0);
        //whenever a rect is painted, the TEI coordinates have to be generated/updated
        updateTEIcoordinates(teiId);
    }
}







/*function to generate unique ids for the elements in the tree*/
function guid() {
    function s4() {
        return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    }
    var testId = s4() + s4() + '-' + s4() + s4();
    return testId;
}
/*produce a shorter Guid*/
function shortGuid() {
    var a = guid().substr(0, 4);
    while (teiDoc.getElementById(a)) {
        a = guid().substr(0, 4);
    }
    return a;
}

function makeTextstageModal() {
    var list = $('#textStagesList');
    var stages = teiDoc.getElementById('creation').querySelectorAll('creation > listChange');
    for (item in stages) {
        list.appendChild(makeStageitemNode(item));
    }
    alert(stages.length);
}

function makeStageitemNode(myItem) {
    var resultingItem;
    if (myItem.name == "listChange") {
    } else if (myItem.name == "change") {
    }
    var children = myItem.childNodes;
    for (item2 in children) {
        resultingItem.appendChild(makeStageitemNode(item2));
    }
}




jQuery.event.special.scrolldelta = {
    // from http://learn.jquery.com/events/event-extensions/
    delegateType: "scroll",
    bindType: "scroll",
    handle: function (event) {
        var handleObj = event.handleObj;
        var targetData = jQuery.data(event.target);
        var ret = null;
        var elem = event.target;
        var isDoc = elem === document;
        var oldTop = targetData.top || 0;
        var oldLeft = targetData.left || 0;
        targetData.top = isDoc ? elem.documentElement.scrollTop + elem.body.scrollTop: elem.scrollTop;
        targetData.left = isDoc ? elem.documentElement.scrollLeft + elem.body.scrollLeft: elem.scrollLeft;
        event.scrollTopDelta = targetData.top - oldTop;
        event.scrollTop = targetData.top;
        event.scrollLeftDelta = targetData.left - oldLeft;
        event.scrollLeft = targetData.left;
        event.type = handleObj.origType;
        ret = handleObj.handler.apply(this, arguments);
        event.type = handleObj.type;
        return ret;
    }
};




var topScroll = 0;
$('#svg_area').on('scrolldelta', function (e) {
    topScroll = e.scrollTop;
    var topDelta = e.scrollTopDelta;
    var left = e.scrollLeft;
    var leftDelta = e.scrollLeftDelta;
    var feedbackText = 'scrollTop: ' + topScroll.toString() + 'px (' + (topDelta >= 0 ? '+': '') + topDelta.toString() + 'px), scrollLeft: ' + left.toString() + 'px (' + (leftDelta >= 0 ? '+': '') + leftDelta.toString() + 'px)';
    console.log(feedbackText);
});


//Rotation function:
function rotateRect(rectId, angles) {
    var result = $.grep(rectangles, function (e) {
        return e.myId == rectId;
    });
    
    result[0].rotAngle = angles;
    
    result[0].draw();
    result[0].scaleFont();
}
