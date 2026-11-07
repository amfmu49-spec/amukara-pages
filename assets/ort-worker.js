/* ort-worker.js — ONNX Runtime worker for the CPU (WASM) separation path.
 *
 * Field report (2026-11-07, iPhone, Muse webview + Safari): creating the
 * session on the page's main thread with the ort.all (JSEP) bundle froze
 * the whole page at "セッションを作成中…" — the elapsed timer stopped at
 * 4.8s, i.e. the main thread blocked inside InferenceSession.create and
 * never returned. This worker owns the session instead, using the
 * WASM-only bundle, so the page UI stays alive while the session is
 * created and inference runs. The page supervises this worker with
 * watchdogs and falls back to a main-thread session if the worker cannot
 * start or stops responding.
 *
 * Protocol:
 *   page -> worker : { type: 'create', buffer }            (model bytes, transferred)
 *   worker -> page : { type: 'created' } | { type: 'create-error', message }
 *   page -> worker : { type: 'run', id, buffer, dims }     (spek chunk, transferred)
 *   worker -> page : { type: 'result', id, buffer } | { type: 'run-error', id, message }
 */
/* Vendored copy (assets/ort.wasm.min.mjs, onnxruntime-web@1.21.0) —
   imported relative to this worker so the page needs no cross-origin
   request at runtime (see the ORT note in index.html). */
import * as ort from './ort.wasm.min.mjs';

if (ort.env && ort.env.wasm) {
  /* The artifact is not cross-origin isolated, so threaded WASM cannot
     run; pin to a single thread explicitly. */
  ort.env.wasm.wasmPaths = new URL('./', import.meta.url).href;
  ort.env.wasm.numThreads = 1;
}

var session = null;
var inputName = '';
var outputName = '';

self.onmessage = async function (ev) {
  var d = ev.data || {};
  if (d.type === 'create') {
    try {
      session = await ort.InferenceSession.create(new Uint8Array(d.buffer), {
        executionProviders: ['wasm'],
        /* Same low-memory session setup as the main-thread path. */
        graphOptimizationLevel: 'disabled',
        enableCpuMemArena: false,
        enableMemPattern: false,
        executionMode: 'sequential'
      });
      inputName = session.inputNames[0];
      outputName = session.outputNames[0];
      self.postMessage({ type: 'created' });
    } catch (e) {
      self.postMessage({
        type: 'create-error',
        message: e && e.message ? e.message : String(e)
      });
    }
  } else if (d.type === 'run') {
    try {
      var tensor = new ort.Tensor('float32', new Float32Array(d.buffer), d.dims);
      var feeds = {};
      feeds[inputName] = tensor;
      var out = await session.run(feeds);
      var t = out[outputName];
      var data = t.data;
      if (!data && t.getData) data = await t.getData();
      var copy = new Float32Array(data);
      if (t.dispose) { try { t.dispose(); } catch (e) {} }
      self.postMessage({ type: 'result', id: d.id, buffer: copy.buffer }, [copy.buffer]);
    } catch (e2) {
      self.postMessage({
        type: 'run-error',
        id: d.id,
        message: e2 && e2.message ? e2.message : String(e2)
      });
    }
  }
};
