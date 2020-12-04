/*
 * WindowManager.js is a lightweight Window Manager written in JavaScript.
 *
 * WindowManager.js a beta and still verry buggy and messy.
 *
 * @author: #JS
 *
 * WindowManager.js is inspired by the single window script "DraggableWindow.js".
 * For DraggableWindow.js see:
 * @author https://twitter.com/blurspline / https://github.com/zz85
 * See post @ http://www.lab4games.net/zz85/blog/2014/11/15/resizing-moving-snapping-windows-with-js-css/
 */

// Array with all Windows
var windows =[];
// currently active/topmost window
var lastMoved;


// All Windows share the same minimal dimensions
var minWidth = 500;
var minHeight = 200;

// Thresholds
var FULLSCREEN_MARGINS = -10;
var MARGINS = 4;
var NAVBARHEIGHT = 42;

// increases with windows, used to keep ghostpane < pane < pane.paneTitle
var zIndex_COUNTER = 120;

//there can only be one lockedWindow...
var lockedWindow;



function DraggableWindow(title) {
    //this.id = paneId;
    //give an id to the window
    this.id = generateWindowId();
    this.buildwindow();
    this.buildghostpane();
    //TODO: what is this line needed for?
    this.pane.paneTitle = this.pane.getElementsByClassName('paneTitle')[0];
    //set the title
    this.setTitle(title);
    
    this.clicked = null;
    this.onRightEdge;
    this.onBottomEdge;
    this.onLeftEdge;
    this.onTopEdge;
    
    this.rightScreenEdge;
    this.bottomScreenEdge;
    
    this.preSnapped;
    
    this.b = this.pane.getBoundingClientRect();
    this.x;
    this.y;
    
    this.redraw = false;
    this.e;
    
    this.button = this.initiateButton();
    
    //lock for windowSnaping. If set to true, the window does not snap on left/right/bottom/top
    this.snapLock = false;
    
    lastMoved = this;
    hintHide();
    this.windowToTop();
    addDraggableWindowEvents(this.pane);
    windows.push(this);
    if (windows.length == 1) {
        animate();
    }
    
    this.openWindow();

}




function LockedWindow(title){
    //inherit regular window constructor
    DraggableWindow.call(this, title);

    //set zIndex higher than bootstrap nav (1030) and bootstrap modal (1050)
    this.pane.style.zIndex = 1070;

    //create a lockpane on top of all other contents (it is styled via css... see css file)
    var lockPane = document.createElement('div');
    lockPane.classList.add('lockPane');
    $('body').append(lockPane);
    this.lockPane = lockPane;
    this.lockPane.style.zIndex = this.pane.style.zIndex - 10;
    $(this.lockPane).fadeIn('fast');
    
    //remove the window-close/minimize buttons and remove the nav-tab for the window
    $('#' + this.buttonId).remove();
    $(this.windowfunctions).remove();
    
    this.deactivateSnap();
    lockedWindow = this;
}

//Link LockedWindow and DraggableWindow constructors: LockedWindow inherits prototype functions of DraggableWindow
LockedWindow.prototype = Object.create(DraggableWindow.prototype);
LockedWindow.prototype.constructor = LockedWindow;

//function to close the locked window. 
function closeLockedWindow() {
    //close the Window (will also activate topmost, so no worry about that!)
    lockedWindow.closeWindow();
    //fade out the lock pane
    $('.lockPane').fadeOut( 'fast', 
                            function(){ 
                                    $('.lockPane').remove();
                                });
}

function generateWindowId() {
    function s4() {
        return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    }
    return 'win-' + s4() + s4() + '-' + s4() + '-' + s4();
}

//build, add and return the windows task-bar button
DraggableWindow.prototype.initiateButton = function () {
    var temp = this;
    var itemLi = document.createElement('li');
    itemLi.classList.add('nav-item');
    var itemLink = document.createElement('a');
    this.buttonId = this.id + 'Btn'
    itemLink.setAttribute('id', this.buttonId);
    itemLink.setAttribute('href', '#');
    itemLink.classList.add('nav-link');
    //itemLink.classList.add('active');
    itemLink.innerHTML = this.title;
    itemLi.appendChild(itemLink);
    $('#windows-section').append(itemLi);
    //temp.showWindow();
    $('#' + this.buttonId).click(
    function () {
        if (temp.isVisible() && temp.id != lastMoved.id) {
            temp.windowToTop()
        } else if (temp.isVisible()) {
            temp.hideWindow();
        } else {
            temp.showWindow();
        }
    });
    return (itemLi);
}

LockedWindow.prototype.block = function(){
       //this will hide the window underneath its locked pane (which is always 10 lower than the window, when the window is visible)
       this.pane.style.zIndex -= 20
}

LockedWindow.prototype.unblock = function(){
      //this will put the window back above its locked pane)
      this.pane.style.zIndex += 20
}

DraggableWindow.prototype.loadURL = function(urlString){
       var tempThis = this;
       console.log(urlString);
       loadDoc(urlString, function (e) {
            //console.log('request successfull');
            var data = jQuery.parseHTML(e.responseText);
            //console.log(data);
            tempThis.setContentHTML(data);
            
        }); 
        
}

DraggableWindow.prototype.setContentHTML = function(htmlData){
        console.log(htmlData);
        $(this.content).append(htmlData);
}

//builds the ghostpane, which is used to indicate snapping and window-resizing to the user
DraggableWindow.prototype.buildghostpane = function () {
    var ghostpaneDiv = document.createElement('div');
    ghostpaneDiv.setAttribute('id', this.id + '_gp');
    ghostpaneDiv.classList.add('ghostpane');
    $(ghostpaneDiv).insertBefore(this.pane);
    this.ghostpane = ghostpaneDiv;
}

DraggableWindow.prototype.deactivateSnap = function(){
    this.snapLock = true;
}
DraggableWindow.prototype.activateSnap = function(){
    this.snapLock = false;
}


//builds a basic window'
DraggableWindow.prototype.buildwindow = function () {
    var windowDiv = document.createElement('div');
    windowDiv.classList.add('pane');
    windowDiv.setAttribute('id', this.id);
    
    var d1Div = document.createElement('div');
    d1Div.classList.add('pane_d1');
    
    var wrapper1 = document.createElement('div');
    wrapper1.classList.add('pane_outerWrapper');
    
    var wrapper2 = document.createElement('div');
    wrapper1.classList.add('pane_innerWrapper');
    
    var headerWrapper = document.createElement('div');
    headerWrapper.classList.add('pane_headerWrapper');
    
    var paneTitle = document.createElement('div');
    paneTitle.classList.add('paneTitle');
    
    
    var windowfunctions = document.createElement('div');
    windowfunctions.classList.add('pane_closeAndResize', 'btn-group', 'btn-group-sm');
    this.windowfunctions = windowfunctions;
    
    var minimizeButton = document.createElement('button');
    minimizeButton.setAttribute('aria-hidden', 'true');
    minimizeButton.classList.add('btn', 'btn-window-border', 'btn-sm');
    /* bind instance to prototype function... */
    minimizeButton.addEventListener('click', this.hideWindow.bind(this), false);
    var minimizeIcon = document.createElement('i');
    minimizeIcon.classList.add('fas', 'fa-window-minimize');
    minimizeButton.appendChild(minimizeIcon)
    windowfunctions.appendChild(minimizeButton);
    this.minimizeIcon = minimizeButton;
    
    var maximizeButton = document.createElement('button');
    maximizeButton.setAttribute('aria-hidden', 'true');
    maximizeButton.classList.add('btn', 'btn-window-border', 'btn-sm');
    maximizeButton.addEventListener('click', this.maximizeWindow.bind(this), false);
    var maximizeIcon = document.createElement('i');
    maximizeIcon.classList.add('fas', 'fa-window-maximize');
    maximizeButton.appendChild(maximizeIcon)
    windowfunctions.appendChild(maximizeButton);
    this.maximizeIcon = maximizeButton;
    
    var closeButton = document.createElement('button');
    closeButton.setAttribute('aria-hidden', 'true');
    closeButton.classList.add('btn', 'btn-window-border', 'btn-sm');
    closeButton.addEventListener('click', this.closeWindow.bind(this), false);
    var closeIcon = document.createElement('i');
    closeIcon.classList.add('fas', 'fa-times');
    closeButton.appendChild(closeIcon)
    windowfunctions.appendChild(closeButton);
    this.closeIcon = closeButton;
    
    
    var windowTitleText = document.createElement('div');
    windowTitleText.classList.add('pane_titleText');
    
    paneTitle.appendChild(windowfunctions);
    paneTitle.appendChild(windowTitleText);
    this.titleText = windowTitleText;
    
    headerWrapper.appendChild(paneTitle);
    
    var contentWrapper = document.createElement('div');
    contentWrapper.classList.add('pane_contentWrapper');
    this.contentWrapper = contentWrapper;
    
    var content = document.createElement('div');
    content.classList.add('pane_singleContent');
    contentWrapper.appendChild(content);
    this.content = content;
    
    var btnToolbar = document.createElement('div');
    btnToolbar.classList.add('btn-toolbar');
    btnToolbar.setAttribute('role', 'toolbar');
    
    
    wrapper2.appendChild(headerWrapper);
    wrapper2.appendChild(contentWrapper);
    wrapper1.appendChild(wrapper2);
    d1Div.appendChild(wrapper1);
    windowDiv.appendChild(d1Div);
    
    
    $('body').append(windowDiv);
    this.pane = windowDiv;
    $(windowDiv).resizable({
      containment: "div.content-wrapper"
    });
    
}



function setBounds(element, x, y, w, h) {
    element.style.left = x + 'px';
    element.style.top = y + 'px';
    element.style.width = w + 'px';
    element.style.height = h + 'px';
}

function hintHide() {
    var ghostpane = lastMoved.ghostpane;
    setBounds(ghostpane, lastMoved.b.left, lastMoved.b.top, lastMoved.b.width, lastMoved.b.height);
    ghostpane.style.opacity = 0;
}


function addDraggableWindowEvents(mypane) {
    // Mouse events
    mypane.paneTitle.addEventListener('mousedown', onMouseDown);
    mypane.addEventListener('mousedown', reOrder);
    
    /*  $(mypane).resize(function (e) {
        //jscrollbar
        if ($('.scroll-pane').data('jsp')) {
            $('.scroll-pane').data('jsp').reinitialise();
        }
    });*/
    
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
    
    // Touch events
    mypane.addEventListener('touchstart', onTouchDown);
    document.addEventListener('touchmove', onTouchMove);
    document.addEventListener('touchend', onTouchEnd);
}


/* can potentially be removed. currently not used.. */
function getWindowById(paneId) {
    var pane = $.grep(windows, function (a) {
        return (a.id == paneId);
    });
    return (pane[0]);
}

function onTouchDown(e) {
    onDown(e.touches[0]);
}

function onTouchMove(e) {
    onMove(e.touches[0]);
}

function onTouchEnd(e) {
    if (e.touches.length == 0) onUp(e.changedTouches[0]);
}

function onMouseDown(e) {
    reOrder(e);
    onDown(e);
}

/* identifies id of currently clicked window and pulls it to top*/

function reOrder(e) {
    var currentId = getParentPaneId(e.target || e.srcElement);
    if (currentId) {
        var currentWindow = getWindowById(currentId);
        if (lastMoved.id != currentWindow.id) {
            currentWindow.windowToTop();
        }
    }
}



DraggableWindow.prototype.setMinDimensions = function (width, height) {
    $(this.pane).css('min-width', width + 'px');
    $(this.pane).css('min-height', height + 'px');
}


/* TODO: check if still in use! */
DraggableWindow.prototype.addFunctionHTML = function (htmlString) {
    //alert('now');
    var newDiv = document.createElement("div");
    newDiv.classList.add('htmlFunction');
    newDiv.innerHTML = htmlString;
}

DraggableWindow.prototype.setTitle = function (myTitleText) {
    this.title = myTitleText;
    this.titleText.innerHTML = myTitleText;
}

/* TODO: check if still in use */
DraggableWindow.prototype.setContent = function (myContentText) {
    this.content.innerHTML = myContentText;
}


/* todo: remove eventually, only used as a model to see how to pass a function as a parameter into a prototype function */
DraggableWindow.prototype.addCustomClosingFunction = function (myFunction) {
    //closeButton.addEventListener('click', this.closeWindow.bind(this), false);
    //myFunction();
    this.closeIcon.addEventListener('click', myFunction, false);
   // this.closeWindow.unbind();
    //this.closeIcon.unbind("click", this.closeWindow());
    //this.closeIcon.addEventListener('click', myFunction);
}

/* drags the window on top of all windows by increasing it's z-index. 
 * The initial z-index starts at zIndex_COUNTER=120 and increses by 3 (ghostpane, pane and title-pane) for each new window that is 
 * pulled to the top. Note that bootstraps default Navbar is on z-index=1030 and bootstraps default modal is at 1050. If unrealistically many 
 * windows are opened, it is possible that the windows are *above* the navbar and the modal. also note that the lockedWindow is pulled (z-index=1070) 
 * to the top manually in order to keep it above the navbar and above the modal.*/
DraggableWindow.prototype.windowToTop = function () {
    $(this.pane).appendTo('body');
    $(this.ghostpane).insertBefore(this.pane);
    
    $(this.ghostpane).css("z-index", zIndex_COUNTER + 1);
    $(this.pane).css("z-index", zIndex_COUNTER + 2);
    $(this.pane.paneTite).css("z-index", zIndex_COUNTER + 3);
    
    zIndex_COUNTER = zIndex_COUNTER + 3;
    
    //highlight the topmost window by css class (remove class from all other windows)
    $('div.pane').removeClass('activeWindow');
    $(this.pane).addClass('activeWindow');
    
    $('#windows-section .nav-item').removeClass('active').blur();
    $(this.button).addClass('active');
    
    lastMoved = this;
}


/* This function is used to show an already existing window (usually a minimized window). 
 * Note: To view a newly initiated window openWindow() offers the more suitable visual effect */
DraggableWindow.prototype.showWindow = function () {
    //current animation (slide down + fade in)
    $(this.pane).css('min-height', 'auto').animate({
        opacity: 'toggle', height: 'toggle'
    },
    400, function () {
        $('div.pane').css('min-height', minHeight);
    });
    $(this.ghostpane).show();
    this.windowToTop();
    $('#' + this.buttonId).addClass('active');
}

/* this function is used to show an already existing window (usually because it is minimized). To open a new window openWindow() offers the more suitable effect */
DraggableWindow.prototype.openWindow = function () {
    //current animation (fade in, for additional slideDown: use showWindow())
    $(this.pane).fadeIn('fast', function () {
        $('div.pane').css('min-height', minHeight);
    });
    $(this.ghostpane).show();
    this.windowToTop();
    $('#' + this.buttonId).addClass('active')
}

DraggableWindow.prototype.hideWindow = function () {
    //current animation (slideUp + fadeOut)
    $(this.pane).css('min-height', '30px').animate({
        height: 'toggle', opacity: 'toggle'
    },
    'fast', function () {
        $('div.pane').css('min-height', minHeight);
    });
    
    $(this.ghostpane).hide(function () {
        //after window is hidden, activate the next topmost window (if there is a visible one)
        activateTopmostWindow();
    });
    $('#' + this.buttonId).removeClass('active')
    $('#windows-section .nav-item').removeClass('active');
}


DraggableWindow.prototype.maximizeWindow = function () {
    
    if (typeof lastMoved.preSnapped === 'undefined' || ! lastMoved.preSnapped) {
        var snapped = {
            x: lastMoved.b.left,
            y: lastMoved.b.top,
            width: lastMoved.b.width,
            height: lastMoved.b.height
        };
        setBounds(this.pane, 0, NAVBARHEIGHT, window.innerWidth, window.innerHeight - NAVBARHEIGHT);
        lastMoved.preSnapped = snapped;
        console.log("before");
        console.log(lastMoved.preSnapped);
    } else {
        setBounds(this.pane,
        lastMoved.preSnapped.x,
        lastMoved.preSnapped.y,
        lastMoved.preSnapped.width,
        lastMoved.preSnapped.height);
        

        console.log("afterwards (restored):");
        console.log(lastMoved.preSnapped);
        lastMoved.preSnapped = "";
    }
}


DraggableWindow.prototype.isVisible = function () {
    return ($(this.pane).is(":visible"));
}


DraggableWindow.prototype.getId = function () {
    return (this.id);
}

/* the window object cannot really destroy itself, but the pane, the ghostpane and the taskbar button can be removed from the DOM and the
window object can be removed from the windows[] array */
DraggableWindow.prototype.closeWindow = function () {
   var tempthis = this;
   $(tempthis.pane).fadeOut('fast', function () {
            $(tempthis.pane).remove();
            $(tempthis.ghostpane).remove();
    });

    
    $(tempthis.button).fadeOut('fast', function () {
        $(tempthis.button).remove();
        activateTopmostWindow();
    });
    var index = windows.indexOf(tempthis);
        if (index !== -1) {
            windows.splice(index, 1);
    }
}


/* highlight the visually topmost window (by z-index) by applying windowToTop(). Used e.g. when the last active window was minimized or closed*/
/* should become prototype function of WindowManager object */
function activateTopmostWindow() {
    var topmostZindex = -1;
    var topmostWindow;
    $(windows).each(function () {
        if ($(this.pane).is(':visible')) {
            if ($(this.pane).css("z-index") > topmostZindex) {
                topmostZindex = $(this.pane).css("z-index");
                topmostWindow = this;
            }
        }
    });
    //alert (topmostWindow.id);
    if (typeof topmostWindow === 'undefined' || ! topmostWindow) {
        console.log("currently there is no visible window that could be made 'topmost'");
    } else {
        topmostWindow.windowToTop();
    }
}

function onDown(e) {
    calc(e);
    lastMoved.e = e;
    
    var isResizing = lastMoved.onRightEdge || lastMoved.onBottomEdge || lastMoved.onTopEdge || lastMoved.onLeftEdge;
    if (isResizing || canMove()) {
        e.preventDefault();
    }
    
    lastMoved.clicked = {
        x: lastMoved.x,
        y: lastMoved.y,
        cx: lastMoved.e.clientX,
        cy: lastMoved.e.clientY,
        w: lastMoved.b.width,
        h: lastMoved.b.height,
        isResizing: isResizing,
        isMoving: ! isResizing && canMove(),
        onTopEdge: lastMoved.onTopEdge,
        onLeftEdge: lastMoved.onLeftEdge,
        onRightEdge: lastMoved.onRightEdge,
        onBottomEdge: lastMoved.onBottomEdge
    };
}

function getParentPaneId(elem) {
    if ($(elem).is('div.pane')) {
        return (elem.id);
    } else if ($(elem).parents('div.pane').length !== 0) {
        return ($(elem).parents('div.pane')[0].id);
    } else return (false);
}

function canMove() {
    var titlebarsize = window.getComputedStyle(lastMoved.pane.paneTitle).getPropertyValue('height').replace("px", "");
    return lastMoved.x > 0 && lastMoved.x < lastMoved.b.width && lastMoved.y > 0 && lastMoved.y < lastMoved.b.height && lastMoved.y < parseInt(titlebarsize);
}

function calc(e) {
    
    lastMoved.b = lastMoved.pane.getBoundingClientRect();
    
    lastMoved.x = e.clientX - lastMoved.b.left;
    lastMoved.y = e.clientY - lastMoved.b.top;
    
    lastMoved.onTopEdge = lastMoved.y < MARGINS;
    lastMoved.onLeftEdge = lastMoved.x < MARGINS;
    lastMoved.onRightEdge = lastMoved.x >= lastMoved.b.width - MARGINS;
    lastMoved.onBottomEdge = lastMoved.y >= lastMoved.b.height - MARGINS;
    
    lastMoved.rightScreenEdge = window.innerWidth - MARGINS;
    lastMoved.bottomScreenEdge = window.innerHeight - MARGINS;
}


function onMove(ee) {
    calc(ee);
    lastMoved.e = ee;
    lastMoved.redraw = true;
}

function animate() {
    var pane = lastMoved.pane;
    var ghostpane = lastMoved.ghostpane;
    //TODO: check if NAVBARHEIGHT is needed here
    var canSnap = !lastMoved.snapLock && window.innerWidth >= lastMoved.b.width && window.innerHeight >= lastMoved.b.height;
    
    requestAnimationFrame(animate);
    if (! lastMoved.redraw) return;
    
    lastMoved.redraw = false;
    //set boundaries for the ghostpane hints for snapping:
    if (lastMoved.clicked && lastMoved.clicked.isMoving) {
        
        if (canSnap && (lastMoved.b.top < FULLSCREEN_MARGINS + NAVBARHEIGHT || lastMoved.b.left < FULLSCREEN_MARGINS || lastMoved.b.right > window.innerWidth - FULLSCREEN_MARGINS || lastMoved.b.bottom > window.innerHeight - FULLSCREEN_MARGINS)) {
            // hintFull();
            setBounds(ghostpane, 0, NAVBARHEIGHT, window.innerWidth, window.innerHeight - NAVBARHEIGHT);
            ghostpane.style.opacity = 0.2;
        } else if (canSnap && lastMoved.b.top < MARGINS + NAVBARHEIGHT) {
            // hintTop();
            setBounds(ghostpane, 0, NAVBARHEIGHT, window.innerWidth, (window.innerHeight - NAVBARHEIGHT) / 2);
            ghostpane.style.opacity = 0.2;
        } else if (canSnap && lastMoved.b.left < MARGINS) {
            // hintLeft();
            setBounds(ghostpane, 0, NAVBARHEIGHT, window.innerWidth / 2, window.innerHeight - NAVBARHEIGHT);
            ghostpane.style.opacity = 0.2;
        } else if (canSnap && lastMoved.b.right > lastMoved.rightScreenEdge) {
            // hintRight();
            setBounds(ghostpane, window.innerWidth / 2, NAVBARHEIGHT, window.innerWidth / 2, window.innerHeight - NAVBARHEIGHT);
            ghostpane.style.opacity = 0.2;
        } else if (canSnap && lastMoved.b.bottom > lastMoved.bottomScreenEdge) {
            // hintBottom();
            setBounds(ghostpane, 0, (window.innerHeight - NAVBARHEIGHT) / 2, window.innerWidth, window.innerWidth / 2);
            ghostpane.style.opacity = 0.2;
        } else {
            hintHide();
        }
        
        if (lastMoved.preSnapped) {
            setBounds(pane, lastMoved.e.clientX - lastMoved.preSnapped.width / 2,
            lastMoved.e.clientY - Math.min(lastMoved.clicked.y, lastMoved.preSnapped.height),
            lastMoved.preSnapped.width,
            lastMoved.preSnapped.height);
            return;
        }
        
        // moving
        pane.style.top = (lastMoved.e.clientY - lastMoved.clicked.y) + 'px';
        pane.style.left = (lastMoved.e.clientX - lastMoved.clicked.x) + 'px';
        
        return;
    }
}



function onUp(e) {
    var pane = lastMoved.pane;
    var canSnap = !lastMoved.snapLock && window.innerWidth > lastMoved.b.width && window.innerHeight > lastMoved.b.height;
    calc(e);
    lastMoved.e = e;
    if (canSnap && lastMoved.clicked && lastMoved.clicked.isMoving) {
        // Snap
        var snapped = {
            x: lastMoved.b.top,
            y: lastMoved.b.left,
            width: lastMoved.b.width,
            height: lastMoved.b.height
        };
        
        if (lastMoved.b.top < FULLSCREEN_MARGINS + NAVBARHEIGHT || lastMoved.b.left < FULLSCREEN_MARGINS || lastMoved.b.right > window.innerWidth - FULLSCREEN_MARGINS || lastMoved.b.bottom > window.innerHeight - (FULLSCREEN_MARGINS + NAVBARHEIGHT)) {
            // hintFull();
            setBounds(pane, 0, NAVBARHEIGHT, window.innerWidth, window.innerHeight - NAVBARHEIGHT);
            lastMoved.preSnapped = snapped;
        } else if (lastMoved.b.top < MARGINS + NAVBARHEIGHT) {
            // hintTop();
            setBounds(pane, 0, NAVBARHEIGHT, window.innerWidth, (window.innerHeight - NAVBARHEIGHT) / 2);
            lastMoved.preSnapped = snapped;
        } else if (lastMoved.b.left < MARGINS) {
            // hintLeft();
            setBounds(pane, 0, NAVBARHEIGHT, window.innerWidth / 2, window.innerHeight - NAVBARHEIGHT);
            lastMoved.preSnapped = snapped;
        } else if (lastMoved.b.right > lastMoved.rightScreenEdge) {
            // hintRight();
            setBounds(pane, window.innerWidth / 2, NAVBARHEIGHT, window.innerWidth / 2, window.innerHeight - NAVBARHEIGHT);
            lastMoved.preSnapped = snapped;
        } else if (lastMoved.b.bottom > lastMoved.bottomScreenEdge) {
            // hintBottom();
            setBounds(pane, 0, (window.innerHeight - NAVBARHEIGHT) / 2, window.innerWidth, window.innerWidth / 2);
            lastMoved.preSnapped = snapped;
        } else {
            lastMoved.preSnapped = null;
        }
        
        hintHide();
    }
    
    //if browser-window is smaller than window, window does not snap and cant move out of window (left and top)
    if (! canSnap && (lastMoved.b.top < 0 || lastMoved.b.left < 0)) {
        var x, y;
        if (lastMoved.b.top < NAVBARHEIGHT) {
            y = NAVBARHEIGHT;
        } else {
            y = lastMoved.b.top;
        }
        if (lastMoved.b.left < 0) {
            x = 0;
        } else {
            x = lastMoved.b.left;
        }
        setBounds(lastMoved.pane, x, y, lastMoved.width, lastMoved.height);
    }
    lastMoved.clicked = null;
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