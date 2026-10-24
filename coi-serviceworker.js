/*! coi-serviceworker v0.1.7 (Guido Zuidhof, MIT) + pck base64 reassembly layer.
 * The web build's index.pck is stored on this branch only as base64 parts
 * (pck.<build>.partNN.b64 + pck-manifest.json) because the publishing channel
 * accepts text files only. When the game engine requests /index.pck, this
 * worker fetches the manifest + parts, decodes and concatenates them, and
 * answers with the original binary. Any failure falls back to a plain
 * network fetch. All other requests keep the original coi COOP/COEP logic. */
function __b64ToBytes(b64) {
	var clean = b64.replace(/\s+/g, "");
	var out = new Uint8Array(Math.floor(clean.length * 3 / 4) + 3);
	var o = 0;
	var CH = 32768; /* multiple of 4, keeps atob chunks aligned */
	for (var i = 0; i < clean.length; i += CH) {
		var bin = atob(clean.slice(i, i + CH));
		for (var j = 0; j < bin.length; j++) out[o++] = bin.charCodeAt(j);
	}
	return out.subarray(0, o);
}
async function __fetchAssembledPck(requestUrl) {
	var base = requestUrl.slice(0, requestUrl.lastIndexOf("/") + 1);
	var mResp = await fetch(base + "pck-manifest.json", { cache: "no-cache" });
	if (!mResp.ok) throw new Error("pck manifest fetch failed: " + mResp.status);
	var manifest = await mResp.json();
	var parts = manifest.parts || [];
	var total = manifest.total_size | 0;
	var texts = await Promise.all(parts.map(function (name) {
		return fetch(base + name).then(function (r) {
			if (!r.ok) throw new Error("pck part fetch failed: " + name);
			return r.text();
		});
	}));
	var buf = new Uint8Array(total);
	var offset = 0;
	for (var k = 0; k < texts.length; k++) {
		var bytes = __b64ToBytes(texts[k]);
		if (offset + bytes.length > total) throw new Error("pck assembly overflow");
		buf.set(bytes, offset);
		offset += bytes.length;
	}
	if (offset !== total) throw new Error("pck size mismatch: " + offset + " != " + total);
	var headers = new Headers();
	headers.set("Content-Type", "application/octet-stream");
	headers.set("Content-Length", String(total));
	headers.set("Cross-Origin-Embedder-Policy", coepCredentialless ? "credentialless" : "require-corp");
	if (!coepCredentialless) headers.set("Cross-Origin-Resource-Policy", "cross-origin");
	headers.set("Cross-Origin-Opener-Policy", "same-origin");
	return new Response(buf, { status: 200, headers: headers });
}
function __pckIntercept(e) {
	var u;
	try { u = new URL(e.request.url); } catch (err) { return false; }
	if (!u.pathname.endsWith("/index.pck")) return false;
	e.respondWith(__fetchAssembledPck(e.request.url).catch(function (err) {
		console.error("pck assembly failed, falling back to network:", err);
		return fetch(e.request);
	}));
	return true;
}
/*! coi-serviceworker v0.1.7 - Guido Zuidhof and contributors, licensed under MIT */
let coepCredentialless=!1;"undefined"==typeof window?(self.addEventListener("install",(()=>self.skipWaiting())),self.addEventListener("activate",(e=>e.waitUntil(self.clients.claim()))),self.addEventListener("message",(e=>{e.data&&("deregister"===e.data.type?self.registration.unregister().then((()=>self.clients.matchAll())).then((e=>{e.forEach((e=>e.navigate(e.url)))})):"coepCredentialless"===e.data.type&&(coepCredentialless=e.data.value))})),self.addEventListener("fetch",(function(e){if(__pckIntercept(e))return;const o=e.request;if("only-if-cached"===o.cache&&"same-origin"!==o.mode)return;const s=coepCredentialless&&"no-cors"===o.mode?new Request(o,{credentials:"omit"}):o;e.respondWith(fetch(s).then((e=>{if(0===e.status)return e;const o=new Headers(e.headers);return o.set("Cross-Origin-Embedder-Policy",coepCredentialless?"credentialless":"require-corp"),coepCredentialless||o.set("Cross-Origin-Resource-Policy","cross-origin"),o.set("Cross-Origin-Opener-Policy","same-origin"),new Response(e.body,{status:e.status,statusText:e.statusText,headers:o})})).catch((e=>console.error(e))))}))):(()=>{const e=window.sessionStorage.getItem("coiReloadedBySelf");window.sessionStorage.removeItem("coiReloadedBySelf");const o="coepdegrade"==e,s={shouldRegister:()=>!e,shouldDeregister:()=>!1,coepCredentialless:()=>!0,coepDegrade:()=>!0,doReload:()=>window.location.reload(),quiet:!1,...window.coi},r=navigator,t=r.serviceWorker&&r.serviceWorker.controller;t&&!window.crossOriginIsolated&&window.sessionStorage.setItem("coiCoepHasFailed","true");const i=window.sessionStorage.getItem("coiCoepHasFailed");if(t){const e=s.coepDegrade()&&!(o||window.crossOriginIsolated);r.serviceWorker.controller.postMessage({type:"coepCredentialless",value:!(e||i&&s.coepDegrade())&&s.coepCredentialless()}),e&&(!s.quiet&&console.log("Reloading page to degrade COEP."),window.sessionStorage.setItem("coiReloadedBySelf","coepdegrade"),s.doReload("coepdegrade")),s.shouldDeregister()&&r.serviceWorker.controller.postMessage({type:"deregister"})}!1===window.crossOriginIsolated&&s.shouldRegister()&&(window.isSecureContext?r.serviceWorker?r.serviceWorker.register(window.document.currentScript.src).then((e=>{!s.quiet&&console.log("COOP/COEP Service Worker registered",e.scope),e.addEventListener("updatefound",(()=>{!s.quiet&&console.log("Reloading page to make use of updated COOP/COEP Service Worker."),window.sessionStorage.setItem("coiReloadedBySelf","updatefound"),s.doReload()})),e.active&&!r.serviceWorker.controller&&(!s.quiet&&console.log("Reloading page to make use of COOP/COEP Service Worker."),window.sessionStorage.setItem("coiReloadedBySelf","notcontrolling"),s.doReload())}),(e=>{!s.quiet&&console.error("COOP/COEP Service Worker failed to register:",e)})):!s.quiet&&console.error("COOP/COEP Service Worker not registered, perhaps due to private mode."):!s.quiet&&console.log("COOP/COEP Service Worker not registered, a secure context is required."))})();