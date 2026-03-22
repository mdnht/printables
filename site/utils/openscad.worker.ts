import { createOpenSCAD } from 'openscad-wasm-prebuilt'

let openscadInstance: any = null;

self.onmessage = async (e: MessageEvent) => {
  const { code, id } = e.data;
  if (!code) return;

  try {
    if (!openscadInstance) {
      openscadInstance = await createOpenSCAD({
        print: (msg: string) => self.postMessage({ type: 'log', message: msg, id }),
        printErr: (msg: string) => self.postMessage({ type: 'error', message: msg, id })
      });
    }
    const stlContent = await openscadInstance.renderToStl(code);
    self.postMessage({ type: 'success', stlContent, id });
  } catch (err: any) {
    self.postMessage({ type: 'fatal', error: err.message || String(err), id });
  }
}
