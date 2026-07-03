export const loaderFileName = "badwars-latest-loader.lua";
export const defaultLoaderRef = "d1d2c8aa0798b78214249a618e402a3ce9591d9f";

export function buildLoader(origin = "https://badwars-production.up.railway.app", ref = defaultLoaderRef) {
  return `shared.BadWarsStatusApi = "${origin}/api/roblox/status"

if delfolder and isfolder and isfolder("badscript") then
    delfolder("badscript")
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/${ref}/badscript/loader.lua", true), "badwars-loader")()`;
}
