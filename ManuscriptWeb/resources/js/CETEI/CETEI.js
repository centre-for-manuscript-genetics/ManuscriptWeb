var CETEI = function () {
    "use strict";
    var e = {
        eg:[ "<pre>", "</pre>"], ptr:[ '<a href="$rw@target">$@target</a>'], ref:[ '<a href="$rw@target">', "</a>"], graphic: function (e) {
            let t = new Image;
            return t.src = this.rw(e.getAttribute("url")), e.hasAttribute("width") && t.setAttribute("width", e.getAttribute("width")), e.hasAttribute("height") && t.setAttribute("height", e.getAttribute("height")), t
        },
        list: {
            "[type=gloss]": function (e) {
                let t = document.createElement("dl");
                for (let r of Array. from (e.children)) if (r.nodeType == Node.ELEMENT_NODE) {
                    if ("tei-label" == r.localName) {
                        let e = document.createElement("dt");
                        e.innerHTML = r.innerHTML, t.appendChild(e)
                    }
                    if ("tei-item" == r.localName) {
                        let e = document.createElement("dd");
                        e.innerHTML = r.innerHTML, t.appendChild(e)
                    }
                }
                return t
            }
        },
        table: function (e) {
            let t = document.createElement("table");
            if (t.innerHTML = e.innerHTML, "tei-head" == t.firstElementChild.localName) {
                let e = t.firstElementChild;
                e.remove();
                let r = document.createElement("caption");
                r.innerHTML = e.innerHTML, t.appendChild(r)
            }
            for (let e of Array. from (t.querySelectorAll("tei-row"))) {
                let t = document.createElement("tr");
                t.innerHTML = e.innerHTML;
                for (let r of Array. from (e.attributes)) t.setAttribute(r.name, r.value);
                e.parentElement.replaceChild(t, e)
            }
            for (let e of Array. from (t.querySelectorAll("tei-cell"))) {
                let t = document.createElement("td");
                e.hasAttribute("cols") && t.setAttribute("colspan", e.getAttribute("cols")), t.innerHTML = e.innerHTML;
                for (let r of Array. from (e.attributes)) t.setAttribute(r.name, r.value);
                e.parentElement.replaceChild(t, e)
            }
            return t
        },
        egXML: function (e) {
            let t = document.createElement("pre");
            return t.innerHTML = this.serialize(e, ! 0), t
        }
    };
    class t {
        constructor (t) {
            if (this.els =[], this.behaviors =[], this.hasStyle = ! 1, this.prefixes =[], t) this.base = t; else try {
                window &&(this.base = window.location.href.replace(/\/[^\/]*$/, "/"))
            }
            catch (e) {
                this.base = ""
            }
            this.behaviors.push(e), this.shadowCSS, this.supportsShadowDom = document.head.createShadowRoot || document.head.attachShadow
        }
        getHTML5(e, t, r) {
            return window.location.href.startsWith(this.base) && e.indexOf("/") >= 0 &&(this.base = e.replace(/\/[^\/]*$/, "/")), new Promise(function (t, r) {
                let a = new XMLHttpRequest; a.open("GET", e), a.send(), a.onload = function () {
                    this.status >= 200 && this.status < 300 ? t(this.response): r(this.statusText)
                },
                a.onerror = function () {
                    r(this.statusText)
                }
            }). catch (function (e) {
                console.log(e)
            }).then(e => this.makeHTML5(e, t, r))
        }
        makeHTML5(e, t, r) {
            let a =(new DOMParser).parseFromString(e, "text/xml");
            return this.domToHTML5(a, t, r)
        }
        domToHTML5(e, t, r) {
            this._fromTEI(e);
            let a = e => {
                let t, i = ! 1;
                switch (e.namespaceURI) {
                    case "http://www.tei-c.org/ns/1.0": t = document.createElement("tei-" + e.tagName);
                    break;
                    case "http://www.tei-c.org/ns/Examples": t = document.createElement("teieg-" + e.tagName);
                    break;
                    case "http://relaxng.org/ns/structure/1.0": t = document.createElement("rng-" + e.tagName);
                    break;
                    default: t = document.importNode(e, ! 1), i = ! 0
                }
                for (let r of Array. from (e.attributes)) ! r.name.startsWith("xmlns") || i ? t.setAttribute(r.name, r.value): "xmlns" == r.name && t.setAttribute("data-xmlns", r.value), "xml:id" != r.name || i || t.setAttribute("id", r.value), "xml:lang" != r.name || i || t.setAttribute("lang", r.value), "rendition" == r.name && t.setAttribute("class", r.value.replace(/#/g, ""));
                if (t.setAttribute("data-teiname", e.localName), 0 == e.childNodes.length && t.setAttribute("data-empty", ""), "tagsDecl" == e.localName) {
                    let r = document.createElement("style");
                    for (let t of Array. from (e.childNodes)) if (t.nodeType == Node.ELEMENT_NODE && "rendition" == t.localName && "css" == t.getAttribute("scheme")) {
                        let e = "";
                        t.hasAttribute("selector") ?(e += t.getAttribute("selector").replace(/([^#, >]+\w*)/g, "tei-$1").replace(/#tei-/g, "#") + "{\n", e += t.textContent):(e += "." + t.getAttribute("xml:id") + "{\n", e += t.textContent), e += "\n}\n", r.appendChild(document.createTextNode(e))
                    }
                    r.childNodes.length > 0 &&(t.appendChild(r), this.hasStyle = ! 0)
                }
                "prefixDef" == e.localName &&(this.prefixes.push(e.getAttribute("ident")), this.prefixes[e.getAttribute("ident")] = {
                    matchPattern: e.getAttribute("matchPattern"), replacementPattern: e.getAttribute("replacementPattern")
                });
                for (let r of Array. from (e.childNodes)) r.nodeType == Node.ELEMENT_NODE ? t.appendChild(a(r)): t.appendChild(r.cloneNode());
                return r && r(t), t
            };
            if (this.dom = a(e.documentElement), this.applyBehaviors(), this.done = ! 0, ! t) return this.dom;
            t(this.dom, this)
        }
        applyBehaviors() {
            window.customElements ? this.define(this.els): this.fallback(this.els)
        }
        addStyle(e, t) {
            this.hasStyle && e.getElementsByTagName("head").item(0).appendChild(t.getElementsByTagName("style").item(0).cloneNode(! 0))
        }
        addShadowStyle(e) {
            this.shadowCSS &&(e.innerHTML = '<style>@import url("' + this.shadowCSS + '");</style>' + e.innerHTML)
        }
        addBehaviors(e) {
            e.handlers && this.behaviors.push(e.handlers), "object" == typeof e && this.behaviors.push(e), e.fallbacks && console.log("Fallback behaviors are no longer used.")
        }
        setBaseUrl(e) {
            this.base = e
        }
        _fromTEI(e) {
            let t = e.documentElement;
            this.els = new Set (Array. from (t.getElementsByTagNameNS("http://www.tei-c.org/ns/1.0", "*"), e => e.tagName)), this.els.add("egXML"), this.els.add(t.tagName)
        }
        _insert(e, t) {
            let r = document.createElement("span");
            for (let t of Array. from (e.childNodes)) t.nodeType !== Node.ELEMENT_NODE || t.hasAttribute("data-processed") || this._processElement(t);
            return t.length > 1 ? r.innerHTML = t[0] + e.innerHTML + t[1]: r.innerHTML = t[0] + e.innerHTML, r
        }
        _processElement(e) {
            if (e.hasAttribute("data-teiname") && ! e.hasAttribute("data-processed")) {
                let t = this.getFallback(e.getAttribute("data-teiname"));
                t &&(this.append(t, e), e.setAttribute("data-processed", ""))
            }
            for (let t of Array. from (e.childNodes)) t.nodeType === Node.ELEMENT_NODE && this._processElement(t)
        }
        _template(e, t) {
            let r = e;
            if (e.search(/$(\w*)(@\w+)/)) {
                let a, i = /\$(\w*)@(\w+)/g;
                for (; a = i.exec(e);) t.hasAttribute(a[2]) &&(r = a[1] && this[a[1]] ? r.replace(a[0], this[a[1]].call(this, t.getAttribute(a[2]))): r.replace(a[0], t.getAttribute(a[2])))
            }
            return r
        }
        tagName(e) {
            return "egXML" == e ? "teieg-" + e.toLowerCase(): "tei-" + e.toLowerCase()
        }
        decorator(e) {
            if (Array.isArray(e)) return this._decorator(e); {
                let t = this;
                return function (r) {
                    for (let a of Object.keys(e)) if (r.matches(a)) return Array.isArray(e[a]) ? t._decorator(e[a]).call(t, r): e[a].call(t, r);
                    if (e._) return Array.isArray(e._) ? t._decorator(e._).call(t, r): e._.call(t, r)
                }
            }
        }
        _decorator(e) {
            let t = this;
            return function (r) {
                let a =[];
                for (let i = 0; i < e.length; i++) a.push(t._template(e[i], r));
                return t._insert(r, a)
            }
        }
        getHandler(e) {
            for (let t = this.behaviors.length -1; t >= 0; t--) if (this.behaviors[t][e]) return "[object Function]" === {
            }.toString.call(this.behaviors[t][e]) ? this.append(this.behaviors[t][e]): this.append(this.decorator(this.behaviors[t][e]))
        }
        getFallback(e) {
            for (let t = this.behaviors.length -1; t >= 0; t--) if (this.behaviors[t][e]) return "[object Function]" === {
            }.toString.call(this.behaviors[t][e]) ? this.behaviors[t][e]: this.decorator(this.behaviors[t][e])
        }
        append(e, t) {
            if (! t) {
                let t = this;
                return function () {
                    let r = e.call(t, this);
                    r && ! t._childExists(this.firstElementChild, r.nodeName) && t._appendBasic(this, r)
                }
            } {
                let r = e.call(this, t);
                r && ! this._childExists(t.firstElementChild, r.nodeName) && this._appendBasic(t, r)
            }
        }
        attach(e, t, r) {
            if (e[t].call(e, r), r.nodeType === Node.ELEMENT_NODE) for (let e of Array. from (r.querySelectorAll("*"))) if (! e.hasAttribute("data-processed")) {
                let t;
                (t = this.getFallback(e.getAttribute("data-teiname"))) && this.append(t, e)
            }
        }
        _childExists(e, t) {
            return !(! e || e.nodeName != t) || e && e.nextElementSibling && this._childExists(e.nextElementSibling, t)
        }
        _appendShadow(e, t) {
            var r = e.attachShadow({
                mode: "open"
            });
            this.addShadowStyle(r), r.appendChild(t)
        }
        _appendBasic(e, t) {
            this.hideContent(e), e.appendChild(t)
        }
        registerAll(e) {
            this.define(e)
        }
        define(e) {
            for (let t of e) try {
                let e = this.getHandler(t);
                window.customElements.define(this.tagName(t), class extends HTMLElement {
                    constructor () {
                        super (), this.matches(":defined") ||(e && e.call(this), this.setAttribute("data-processed", ""))
                    }
                    connectedCallback() {
                        this.hasAttribute("data-processed") ||(e && e.call(this), this.setAttribute("data-processed", ""))
                    }
                })
            }
            catch (e) {
                console.log("an element couldn't be registered or is already registered: ");// + this.tagName(t));
            }
        }
        fallback(e) {
            for (let t of e) {
                let e = this.getFallback(t);
                if (e) for (let r of Array. from ((this.dom && ! this.done ? this.dom: document).getElementsByTagName(this.tagName(t)))) r.hasAttribute("data-processed") || this.append(e, r)
            }
        }
        rw(e) {
            return e.match(/^(?:http|mailto|file|\/|#).*$/) ? e: this.base + e
        }
        first(e) {
            return e.replace(/ .*$/, "")
        }
        normalizeURI(e) {
            return this.rw(this.first(e))
        }
        repeat(e, t) {
            let r = "";
            for (let a = 0; a < t; a++) r += e;
            return r
        }
        copyAndReset(e) {
            let t = e => {
                let r = e.nodeType === Node.ELEMENT_NODE ? document.createElement(e.nodeName): e.cloneNode(! 0);
                if (e.attributes) for (let t of Array. from (e.attributes)) "data-processed" !== t.name && r.setAttribute(t.name, t.value);
                for (let a of Array. from (e.childNodes)) if (a.nodeType == Node.ELEMENT_NODE) {
                    if (! e.hasAttribute("data-empty")) {
                        if (a.hasAttribute("data-original")) {
                            for (let e of Array. from (a.childNodes)) r.appendChild(t(e));
                            return r
                        }
                        r.appendChild(t(a))
                    }
                } else r.appendChild(a.cloneNode());
                return r
            };
            return t(e)
        }
        serialize(e, t) {
            let r = "";
            if (! t) {
                r += "&lt;" + e.getAttribute("data-teiname");
                for (let t of Array. from (e.attributes)) t.name.startsWith("data-") ||[ "id", "lang", "class"].includes(t.name) ||(r += " " + t.name + '="' + t.value + '"'), "data-xmlns" == t.name &&(r += ' xmlns="' + t.value + '"');
                e.childNodes.length > 0 ? r += ">": r += "/>"
            }
            for (let t of Array. from (e.childNodes)) switch (t.nodeType) {
                case Node.ELEMENT_NODE: r += this.serialize(t);
                break;
                case Node.PROCESSING_INSTRUCTION_NODE: r += "&lt;?" + t.nodeValue + "?>";
                break;
                case Node.COMMENT_NODE: r += "&lt;!--" + t.nodeValue + "--\x3e";
                break;
                default: r += t.nodeValue.replace(/</g, "&lt;")
            }
            return ! t && e.childNodes.length > 0 &&(r += "&lt;/" + e.getAttribute("data-teiname") + ">"), r
        }
        hideContent(e) {
            if (e.childNodes.length > 0) {
                let t = document.createElement("span");
                e.appendChild(t), t.setAttribute("style", "display:none;"), t.setAttribute("data-original", "");
                for (let r of Array. from (e.childNodes)) r !== t && t.appendChild(e.removeChild(r))
            }
        }
        unEscapeEntities(e) {
            return e.replace(/&gt;/, ">").replace(/&quot;/, '"').replace(/&apos;/, "'").replace(/&amp;/, "&")
        }
        static savePosition() {
            window.localStorage.setItem("scroll", window.scrollY)
        }
        static restorePosition() {
            window.location.hash || window.localStorage.getItem("scroll") && setTimeout(function () {
                window.scrollTo(0, localStorage.getItem("scroll"))
            },
            100)
        }
        fromODD() {
        }
    }
    try {
        window &&(window.CETEI = t, window.addEventListener("beforeunload", t.savePosition), window.addEventListener("load", t.restorePosition))
    }
    catch (e) {
    }
    return t
}
();
