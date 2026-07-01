loadstring[[
	getgenv().LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(func) return func end
	getgenv().LPH_JIT = LPH_JIT or function(func) return func end
    getgenv().LPH_JIT_MAX = LPH_JIT_MAX or function(func) return func end
]]()

local a=shared.BadwarsLoader
or setmetatable({},{
__index=function()
return function(...)
return...
end
end,
})


local b=a:wrap(function(b)
b()
end,{
name="Internal | run",
})



local c=a.BadwarsEvents
local d=a.Services







local function mprint(e,f,g)
f=f or 0
g=g or{}
if g[e]then
print(string.rep(" ",f).."<Cyclic Reference>")
return
end
g[e]=true
for h,i in pairs(e)do
local j=string.rep(" ",f)
if type(i)=="table"then
print(j..tostring(h).." = {")
mprint(i,f+4,g)
print(j.."}")
else
print(j..tostring(h).." = "..tostring(i))
end
end
local h=getmetatable(e)
if h then
print(string.rep(" ",f).."Metatable:")
if type(h)~="table"then
print(string.rep(" ",f).."Metatable is not a table: "..tostring(h))
else
for i,j in pairs(h)do
local k=string.rep(" ",f+4)
if type(j)=="function"then
print(k..tostring(i).." = <function>")
elseif type(j)=="table"then
print(k..tostring(i).." = {")
mprint(j,f+8,g)
print(k.."}")
else
print(k..tostring(i).." = "..tostring(j))
end
end
end
end
end

pcall(function()
for e,f in game:GetChildren()do
if tostring(f)=="CoreGui"then
continue
end
local g=a.Services[f.Name]
if g~=nil then
getgenv()[f.Name]=g
end
end
end)

local e=d.RunService
local f=d.GuiService
local g=d.StarterGui
local h=d.Players
local i=d.HttpService
local j=d.TweenService
local k=d.UserInputService
local l=d.TextChatService
local m=d.UserInputService
local n=d.ReplicatedStorage
local o=d.CollectionService
local p=d.ContextActionService

local q=identifyexecutor and table.find({"AWP","Nihon"},({identifyexecutor()})[1])and isnetworkowner
or function()
return true
end
local r=workspace.CurrentCamera
local s=h.LocalPlayer
local t=getcustomasset

local u=shared.vape
local v=u.Libraries.tween
local w=u.Libraries.color
local x=u.Libraries.entity
local y=u.Libraries.uipallet
local z=u.Libraries.whitelist
local A=u.Libraries.targetinfo
local B=u.Libraries.prediction
local C=u.Libraries.sessioninfo
local D=u.Libraries.getfontsize
local E=u.Libraries.getcustomasset

local F={
attackReach=0,
attackReachUpdate=tick(),
damageBlockFail=tick(),
hand={},
inventory={
inventory={
items={},
armor={},
},
hotbar={},
},
inventories={},
matchState=0,
queueType="bedwars_test",
tools={},
}
local G={}
local H={}
local I={}
local J
local K
local L,M,N,O,P={},{},{}

local function addBlur(Q)
local R=Instance.new"ImageLabel"
R.Name="Blur"
R.Size=UDim2.new(1,89,1,52)
R.Position=UDim2.fromOffset(-48,-31)
R.BackgroundTransparency=1
R.Image=E"newvape/assets/new/blur.png"
R.ScaleType=Enum.ScaleType.Slice
R.SliceCenter=Rect.new(52,31,261,502)
R.Parent=Q
return R
end

local function collection(Q,R,S,T)
if type(R)=="function"then
S=R
R=nil
end
Q=typeof(Q)~="table"and{Q}or Q
local U,V={},{}

for W,X in Q do
table.insert(
V,
o:GetInstanceAddedSignal(X):Connect(function(Y)
if S then
S(U,Y,X)
return
end
table.insert(U,Y)
end)
)
table.insert(
V,
o:GetInstanceRemovedSignal(X):Connect(function(Y)
if T then
T(U,Y,X)
return
end
Y=table.find(U,Y)
if Y then
table.remove(U,Y)
end
end)
)

for Y,Z in o:GetTagged(X)do
if S then
S(U,Z,X)
continue
end
table.insert(U,Z)
end
end

local W=function(W)
for X,Y in V do
Y:Disconnect()
end
table.clear(V)
table.clear(U)
table.clear(W)
end
if R then
R:Clean(W)
end
return U,W
end

local function getBestArmor(Q)
local R,S=0

for T,U in F.inventory.inventory.items do
local V=U and L.ItemMeta[U.itemType]or{}

if V.armor and V.armor.slot==Q then
local W=(V.armor.damageReductionMultiplier or 0)

if W>R then
S,R=U,W
end
end
end

return S
end

local function getBow()
local Q,R,S=0
for T,U in F.inventory.inventory.items do
local V=L.ItemMeta[U.itemType].projectileSource
if V and table.find(V.ammoItemTypes,"arrow")then
local W=L.ProjectileMeta[V.projectileType"arrow"].combat.damage or 0
if W>Q then
R,S,Q=U,T,W
end
end
end
return R,S
end

local function getItem(Q,R)
for S,T in(R or F.inventory.inventory.items)do
if T.itemType==Q then
return T,S
end
end
return nil
end

local function getRoactRender(Q)
return debug.getupvalue(debug.getupvalue(debug.getupvalue(Q,3).render,2).render,1)
end

local function getSword()
local Q,R,S=0
for T,U in F.inventory.inventory.items do
local V=L.ItemMeta[U.itemType].sword
if V then
local W=V.damage or 0
if W>Q then
R,S,Q=U,T,W
end
end
end
return R,S
end

local function getTool(Q)
local R,S,T=0
for U,V in F.inventory.inventory.items do
local W=L.ItemMeta[V.itemType].breakBlock
if W then
local X=W[Q]or 0
if X>R then
S,T,R=V,U,X
end
end
end
return S,T
end

local function getWool()
for Q,R in(inv or F.inventory.inventory.items)do
if R.itemType:find"wool"then
return R and R.itemType,R and R.amount
end
end
end

local function getStrength(Q)
if not Q.Player then
return 0
end

local R=0
for S,T in(F.inventories[Q.Player]or{items={}}).items do
local U=L.ItemMeta[T.itemType]
if U and U.sword and U.sword.damage>R then
R=U.sword.damage
end
end

return R
end

local function getPlacedBlock(Q)
if not Q then
return
end
local R=L.BlockController:getBlockPosition(Q)
return L.BlockController:getStore():getBlockAt(R),R
end
getgenv().getPlacedBlock=getPlacedBlock

local function getBlocksInPoints(Q,R)
local S,T=L.BlockController:getStore(),{}
for U=Q.X,R.X do
for V=Q.Y,R.Y do
for W=Q.Z,R.Z do
local X=Vector3.new(U,V,W)
if S:getBlockAt(X)then
table.insert(T,X*3)
end
end
end
end
return T
end

local function getNearGround(Q)
Q=Vector3.new(3,3,3)*(Q or 10)
local R,S,T=x.character.RootPart.Position,60
local U=getBlocksInPoints(
L.BlockController:getBlockPosition(R-Q),
L.BlockController:getBlockPosition(R+Q)
)

for V,W in U do
if not getPlacedBlock(W+Vector3.new(0,3,0))then
local X=(R-W).Magnitude
if X<S then
S,T=X,W+Vector3.new(0,3,0)
end
end
end

table.clear(U)
return T
end

local function getShieldAttribute(Q)
local R=0
for S,T in Q:GetAttributes()do
if S:find"Shield"and type(T)=="number"and T>0 then
R+=T
end
end
return R
end

local function getSpeed()
local Q,R,S=0,true,L.SprintController:getMovementStatusModifier():getModifiers()

for T in S do
local U=T.constantSpeedMultiplier and T.constantSpeedMultiplier or 0
if U and U>math.max(Q,1)then
R=false
Q=U-(0.06*math.round(U))
end
end

for T in S do
Q+=math.max((T.moveSpeedMultiplier or 0)-1,0)
end

if Q>0 and R then
Q+=0.16+(0.02*math.round(Q))
end

return 20*(Q+1)
end
getgenv().getSpeed=getSpeed

local function getTableSize(Q)
local R=0
for S in Q do
R+=1
end
return R
end

local function hotbarSwitch(Q)
if Q and F.inventory.hotbarSlot~=Q then
L.Store:dispatch{
type="InventorySelectHotbarSlot",
slot=Q,
}
c.InventoryChanged.Event:Wait()
return true
end
return false
end
getgenv().hotbarSwitch=hotbarSwitch

local function isFriend(Q,R)
if u.Categories.Friends.Options["Use friends"].Enabled then
local S=table.find(u.Categories.Friends.ListEnabled,Q.Name)and true
if R then
S=S and u.Categories.Friends.Options["Recolor visuals"].Enabled
end
return S
end
return nil
end

local function isTarget(Q)
return table.find(u.Categories.Targets.ListEnabled,Q.Name)and true
end

local function notif(...)
return u:CreateNotification(...)
end

local function removeTags(Q)
Q=Q:gsub("<br%s*/>","\n")
return(Q:gsub("<[^<>]->",""))
end

local function roundPos(Q)
return Vector3.new(math.round(Q.X/3)*3,math.round(Q.Y/3)*3,math.round(Q.Z/3)*3)
end

local function switchItem(Q,R)
R=R or 0.05
local S=s.Character and s.Character:FindFirstChild"HandInvItem"or nil
if S and S.Value~=Q and Q.Parent~=nil then
task.spawn(function()
L.Client:Get(M.EquipItem):CallServerAsync{hand=Q}
end)
S.Value=Q
if R>0 then
task.wait(R)
end
return true
end
end
getgenv().switchItem=switchItem

local function waitForChildOfType(Q,R,S,T)
S=S or 3
local U,V=tick()+S
repeat
V=T and Q[R]or Q:FindFirstChildOfClass(R)
if V and V.Name~="UpperTorso"or U<tick()then
break
end
task.wait()
until false
return V
end

local Q,R={},{}
local S
local T

local function modifyVelocity(U)
if U:IsA"BasePart"and U.Name~="HumanoidRootPart"and not R[U]then
R[U]=U.CustomPhysicalProperties or"none"
U.CustomPhysicalProperties=PhysicalProperties.new(0.0001,0.2,0.5,1,1)
end
end

local function updateVelocity(U)
local V=getTableSize(Q)>0
if T~=V or U then
if S then
S:Disconnect()
end
if V then
if x.isAlive then
for W,X in x.character.Character:GetDescendants()do
modifyVelocity(X)
end
S=x.character.Character.DescendantAdded:Connect(modifyVelocity)
end
else
for W,X in R do
W.CustomPhysicalProperties=X~="none"and X or nil
end
table.clear(R)
end
end
T=V
end

local U={
hannah=5,
spirit_assassin=4,
dasher=3,
jade=2,
regent=1,
}

local V={
Damage=function(V,W)
return V.Entity.Character:GetAttribute"LastDamageTakenTime"
<W.Entity.Character:GetAttribute"LastDamageTakenTime"
end,
Threat=function(V,W)
return getStrength(V.Entity)>getStrength(W.Entity)
end,
Kit=function(V,W)
return(V.Entity.Player and U[V.Entity.Player:GetAttribute"PlayingAsKits"]or 0)
>(W.Entity.Player and U[W.Entity.Player:GetAttribute"PlayingAsKits"]or 0)
end,
Health=function(V,W)
return V.Entity.Health<W.Entity.Health
end,
Angle=function(V,W)
local X=x.character.RootPart.Position
local Y=x.character.RootPart.CFrame.LookVector*Vector3.new(1,0,1)
local Z=
math.acos(Y:Dot(((V.Entity.RootPart.Position-X)*Vector3.new(1,0,1)).Unit))
local _=
math.acos(Y:Dot(((W.Entity.RootPart.Position-X)*Vector3.new(1,0,1)).Unit))
return Z<_
end,
}

if not isfolder"vwmeta"then
makefolder"vwmeta"
end
local W=shared.META_COMMIT or"main"
local X=W
if isfile"newvape/profiles/metacommit.txt"then
X=readfile"newvape/profiles/metacommit.txt"
end
pcall(writefile,"newvape/profiles/metacommit.txt",W)
local Y=setmetatable({},{
__index=function(Y)
return Y
end,
__call=function(Y)
return Y
end,
__newindex=function(Y)
return Y
end,
})
local function fetchWithRetry(Z)
for _=1,4 do
local aa,ab=pcall(u.http_function,Z)
if aa and ab and ab~=""and ab~="404: Not Found"then
return ab
end
warn(string.format("[VW Meta] Attempt %d/4 failed, retrying in %ds",_,2^_))
task.wait(2^_)
end
error("HTTP failed after 4 retries: "..Z)
end
local aa=shared.ACTIVE_LOADER or Y
local ab
ab=function(Z,_)
if not isfolder"vwmeta"then
makefolder"vwmeta"
end
aa:Update(`Loading META {Z}.json`,40)
local ac
_=_ or"none"
local ad
if _=="http"or W~="main"and W~=X or not isfile(`vwmeta/{Z}.json`)then
ad="http"
ac=
fetchWithRetry(`https://files.vapebadwars.xyz/VapeBadwars/VWMeta/{W}/Bedwars/{Z}.json`)
else
ad="file"
ac=readfile(`vwmeta/{Z}.json`)
end
local ae,af=pcall(function()
return HttpService:JSONDecode(ac)
end)
if not ae then
if _=="none"and ad=="file"then
pcall(delfile,`vwmeta/{Z}.json`)
return ab(Z,"http")
else
errorNotification(
"Meta Loading Failure",
`Failure loading {Z}.json! Badwars might not function properly :c Try restarting later`,
7
)
return setmetatable({},{
__index=function(ag)
return ag
end,
__newindex=function(ag)
return ag
end,
__call=function(ag)
return ag
end,
__tostring=function()
return`{Z}.json BACKUP_META`
end,
})
end
end
return ae and af
end

b(function()
local ac=x.start
local function customEntity(ad)
if ad:HasTag"inventory-entity"and(not ad:HasTag"Monster"and not ad:HasTag"trainingRoomDummy")then
return
end
if ad:HasTag"trainingRoomDummy"and ad.Name:find"Friendly"then
return
end

x.addEntity(ad,nil,ad:HasTag"Drone"and function(ae)
local af=h:GetPlayerByUserId(ae.Character:GetAttribute"PlayerUserId")
return not af or s:GetAttribute"Team"~=af:GetAttribute"Team"
end or function(ae)
return s:GetAttribute"Team"~=ae.Character:GetAttribute"Team"
end)
end

x.start=function()
ac()
if x.Running then
for ad,ae in o:GetTagged"entity"do
customEntity(ae)
end
table.insert(
x.Connections,
o:GetInstanceAddedSignal"entity":Connect(customEntity)
)
table.insert(
x.Connections,
o:GetInstanceRemovedSignal"entity":Connect(function(ad)
x.removeEntity(ad)
end)
)
end
end

x.addPlayer=function(ad)
if ad.Character then
x.refreshEntity(ad.Character,ad)
end
x.PlayerConnections[ad]={
ad.CharacterAdded:Connect(function(ae)
x.refreshEntity(ae,ad)
end),
ad.CharacterRemoving:Connect(function(ae)
x.removeEntity(ae,ad==s)
end),
ad:GetAttributeChangedSignal"Team":Connect(function()
for ae,af in x.List do
if af.Targetable~=x.targetCheck(af)then
x.refreshEntity(af.Character,af.Player)
end
end

if ad==s then
x.start()
else
x.refreshEntity(ad.Character,ad)
end
end),
}
end

x.addEntity=function(ad,ae,af)
if not ad then
return
end
x.EntityThreads[ad]=task.spawn(function()
local ag,Z,_
if ae then
ag=waitForChildOfType(ad,"Humanoid",10)
Z=ag
and waitForChildOfType(ag,"RootPart",workspace.StreamingEnabled and 9e9 or 10,true)
_=ad:WaitForChild("Head",10)or Z
else
ag={HipHeight=0.5}
Z=waitForChildOfType(ad,"PrimaryPart",10,true)
_=Z
end
local ah=ae
and ae~=s
and{
ad:WaitForChild("ArmorInvItem_0",5),
ad:WaitForChild("ArmorInvItem_1",5),
ad:WaitForChild("ArmorInvItem_2",5),
ad:WaitForChild("HandInvItem",5),
}
or{}

if ag and Z then
local ai={
Connections={},
Character=ad,
Health=(ad:GetAttribute"Health"or 100)+getShieldAttribute(ad),
Head=_,
Humanoid=ag,
HumanoidRootPart=Z,
HipHeight=ag.HipHeight
+(Z.Size.Y/2)
+(ag.RigType==Enum.HumanoidRigType.R6 and 2 or 0),
Jumps=0,
JumpTick=tick(),
Jumping=false,
LandTick=tick(),
MaxHealth=ad:GetAttribute"MaxHealth"or 100,
NPC=ae==nil,
Player=ae,
RootPart=Z,
TeamCheck=af,
}

if ae==s then
ai.AirTime=tick()
x.character=ai
x.isAlive=true
x.Events.LocalAdded:Fire(ai)
table.insert(
x.Connections,
ad.AttributeChanged:Connect(function(aj)
c.AttributeChanged:Fire(aj)
end)
)
else
ai.Targetable=x.targetCheck(ai)

for aj,ak in x.getUpdateConnections(ai)do
table.insert(
ai.Connections,
ak:Connect(function()
ai.Health=(ad:GetAttribute"Health"or 100)+getShieldAttribute(ad)
ai.MaxHealth=ad:GetAttribute"MaxHealth"or 100
x.Events.EntityUpdated:Fire(ai)
end)
)
end

for aj,ak in ah do
table.insert(
ai.Connections,
ak:GetPropertyChangedSignal"Value":Connect(function()
task.delay(0.1,function()
if L.getInventory then
F.inventories[ae]=L.getInventory(ae)
x.Events.EntityUpdated:Fire(ai)
end
end)
end)
)
end

if ae then
local aj=ad:FindFirstChild"Animate"
if aj then
pcall(function()
aj=aj.jump:FindFirstChildWhichIsA"Animation".AnimationId
table.insert(
ai.Connections,
ag.Animator.AnimationPlayed:Connect(function(ak)
pcall(function()
if ak.Animation.AnimationId=="rbxassetid://913384386"then
ak:Stop()
ak:Destroy()
end
end)
if ak.Animation.AnimationId==aj then
ai.JumpTick=tick()
ai.Jumps+=1
ai.LandTick=tick()+1
ai.Jumping=ai.Jumps>1
end
end)
)
end)
end

task.delay(0.1,function()
if L.getInventory then
F.inventories[ae]=L.getInventory(ae)
end
end)
end
table.insert(x.List,ai)
x.Events.EntityAdded:Fire(ai)
end

table.insert(
ai.Connections,
ad.ChildRemoved:Connect(function(aj)
if aj==Z or aj==ag or aj==_ then
if aj==Z and ag.RootPart then
Z=ag.RootPart
ai.RootPart=ag.RootPart
ai.HumanoidRootPart=ag.RootPart
return
end
x.removeEntity(ad,ae==s)
end
end)
)
end
x.EntityThreads[ad]=nil
end)
end

x.getUpdateConnections=function(ad)
local ae=ad.Character
local af={
ae:GetAttributeChangedSignal"Health",
ae:GetAttributeChangedSignal"MaxHealth",
{
Connect=function()
ad.Friend=ad.Player and isFriend(ad.Player)or nil
ad.Target=ad.Player and isTarget(ad.Player)or nil
return{Disconnect=function()end}
end,
},
}

if ad.Player then
table.insert(af,ad.Player:GetAttributeChangedSignal"PlayingAsKits")
end

for ag,ah in ae:GetAttributes()do
if ag:find"Shield"and type(ah)=="number"then
table.insert(af,ae:GetAttributeChangedSignal(ag))
end
end

return af
end

x.targetCheck=function(ad)
if ad.TeamCheck then
return ad:TeamCheck()
end
if ad.NPC then
return true
end
if isFriend(ad.Player)then
return false
end
if not select(2,z:get(ad.Player))then
return false
end
return s:GetAttribute"Team"~=ad.Player:GetAttribute"Team"
end
u:Clean(x.Events.LocalAdded:Connect(updateVelocity))
end)
x.start()

b(function()
local ac,ad
repeat
ac,ad=pcall(function()
return debug.getupvalue(require(s.PlayerScripts.TS.knit).setup,9)
end)
if ac then
break
end
task.wait()
until ac

if not debug.getupvalue(ad.Start,1)then
repeat
task.wait()
until debug.getupvalue(ad.Start,1)
end

local ae=require(n.rbxts_include.node_modules["@flamework"].core.out).Flamework
local af=require(n.TS.inventory["inventory-util"]).InventoryUtil
local ag=require(n.TS.remotes).default.Client
local ah,ai=ag.Get

local function getupvalue(aj,ak)
return debug.getupvalue(aj,ak)
end









local function safeRequire(aj,ak)
local Z,_=pcall(ak)
if not Z then
notif("Vape","Failed to load ["..aj.."]: "..tostring(_),10,"alert")
return nil
end
return _
end

L=setmetatable({
SharedConstants=safeRequire("SharedConstants",function()
return require(n.TS["shared-constants"])
end),
CooldownController=safeRequire("CooldownController",function()
return ae.resolveDependency
"@easy-games/game-core:client/controllers/cooldown/cooldown-controller@CooldownController"

end),
AbilityController=safeRequire("AbilityController",function()
return ae.resolveDependency
"@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController"

end),
AnimationType=safeRequire("AnimationType",function()
return require(n.TS.animation["animation-type"]).AnimationType
end),
AnimationUtil=safeRequire("AnimationUtil",function()
return require(
n.rbxts_include.node_modules["@easy-games"]["game-core"].out.shared.util["animation-util"]
).AnimationUtil
end),
AppController=safeRequire("AppController",function()
return require(
n.rbxts_include.node_modules["@easy-games"]["game-core"].out.client.controllers["app-controller"]
).AppController
end),
BedBreakEffectMeta=safeRequire("BedBreakEffectMeta",function()
return require(n.TS.locker["bed-break-effect"]["bed-break-effect-meta"]).BedBreakEffectMeta
end),
BedwarsKitMeta=safeRequire("BedwarsKitMeta",function()
return require(n.TS.games.bedwars.kit["bedwars-kit-meta"]).BedwarsKitMeta
end),
BlockBreaker=safeRequire("BlockBreaker",function()
return ad.Controllers.BlockBreakController.blockBreaker
end),
BlockSelector=safeRequire("BlockSelector",function()
return ad.Controllers.BlockBreakController.blockBreaker.clientManager:getBlockSelector()
end),
BlockController=safeRequire("BlockController",function()
return require(n.rbxts_include.node_modules["@easy-games"]["block-engine"].out).BlockEngine
end),
BlockEngine=safeRequire("BlockEngine",function()
return require(s.PlayerScripts.TS.lib["block-engine"]["client-block-engine"]).ClientBlockEngine
end),
BlockPlacer=safeRequire("BlockPlacer",function()
return require(
n.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.placement["block-placer"]
).BlockPlacer
end),
ClickHold=safeRequire("ClickHold",function()
return require(
n.rbxts_include.node_modules["@easy-games"]["game-core"].out.client.ui.lib.util["click-hold"]
).ClickHold
end),
Client=ag,
ClientConstructor=safeRequire("ClientConstructor",function()
return require(n.rbxts_include.node_modules["@rbxts"].net.out.client)
end),
ClientDamageBlock=safeRequire("ClientDamageBlock",function()
return require(
n.rbxts_include.node_modules["@easy-games"]["block-engine"].out.shared.remotes
).BlockEngineRemotes.Client
end),
CombatConstant=safeRequire("CombatConstant",function()
return require(n.TS.combat["combat-constant"]).CombatConstant
end),
DamageIndicator=safeRequire("DamageIndicator",function()
return ad.Controllers.DamageIndicatorController.spawnDamageIndicator
end),
EmoteType=safeRequire("EmoteType",function()
return require(n.TS.locker.emote["emote-type"]).EmoteType
end),
GameAnimationUtil=safeRequire("GameAnimationUtil",function()
return require(n.TS.animation["animation-util"]).GameAnimationUtil
end),
getIcon=function(aj,ak)
local Z=L.ItemMeta and L.ItemMeta[aj.itemType]
return Z and ak and Z.image or""
end,
getInventory=function(aj)
local ak,Z=pcall(function()
return af.getInventory(aj)
end)
return ak and Z or{
items={},
armor={},
}
end,
isKitEquipped=function(aj)
if not aj then
return
end
shared.isKitEquippedCache=shared.isKitEquippedCache or{}
aj=tostring(aj)
if shared.isKitEquippedCache[aj]~=nil then
return shared.isKitEquippedCache[aj]
end
if F.queueType~="bedwars_text"and F.queueType:find"combined_kit"then
for ak,Z in{"equippedKit","equippedKit2"}do
if F[Z]~=nil and F[Z]==aj then
shared.isKitEquippedCache[aj]=true
return true
end
end
else
shared.isKitEquippedCache[aj]=(F.equippedKit==aj)
return F.equippedKit==aj
end
shared.isKitEquippedCache[aj]=false
return false
end,
resolveEquippedKit=function(aj)
aj=aj or s:GetAttribute"PlayingAsKits"
if not aj then
F.equippedKit=nil
F.equippedKit2=nil
else
aj=tostring(aj)
if aj:find","then
local ak=aj:split","
F.equippedKit=ak[1]
F.equippedKit2=ak[2]
else
F.equippedKit=aj
F.equippedKit2=s:GetAttribute"miner"and"miner"or nil
end
end
end,
KillEffectMeta=safeRequire("KillEffectMeta",function()
return require(n.TS.locker["kill-effect"]["kill-effect-meta"]).KillEffectMeta
end),
KillFeedController=safeRequire("KillFeedController",function()
return ae.resolveDependency
"client/controllers/game/kill-feed/kill-feed-controller@KillFeedController"

end),
Knit=ad,
KnockbackUtil=safeRequire("KnockbackUtil",function()
return require(n.TS.damage["knockback-util"]).KnockbackUtil
end),
MageKitUtil=safeRequire("MageKitUtil",function()
return require(n.TS.games.bedwars.kit.kits.mage["mage-kit-util"]).MageKitUtil
end),
NametagController=safeRequire("NametagController",function()
return ad.Controllers.NametagController
end),
PartyController=safeRequire("PartyController",function()
return ae.resolveDependency"@easy-games/lobby:client/controllers/party-controller@PartyController"
end),
ProjectileMeta=safeRequire("ProjectileMeta",function()
return require(n.TS.projectile["projectile-meta"]).ProjectileMeta
end),
QueryUtil=safeRequire("QueryUtil",function()
return require(n.rbxts_include.node_modules["@easy-games"]["game-core"].out).GameQueryUtil
end),
QueueCard=safeRequire("QueueCard",function()
return require(s.PlayerScripts.TS.controllers.global.queue.ui["queue-card"]).QueueCard
end),
QueueMeta=safeRequire("QueueMeta",function()
return require(n.TS.game["queue-meta"]).QueueMeta
end),
Roact=safeRequire("Roact",function()
return require(n.rbxts_include.node_modules["@rbxts"].roact.src)
end),
RuntimeLib=safeRequire("RuntimeLib",function()
return require(n.rbxts_include.RuntimeLib)
end),
SoundList=safeRequire("SoundList",function()
return require(n.TS.sound["game-sound"]).GameSound
end),
SoundManager=safeRequire("SoundManager",function()
return require(n.rbxts_include.node_modules["@easy-games"]["game-core"].out).SoundManager
end),
Store=safeRequire("Store",function()
return require(s.PlayerScripts.TS.ui.store).ClientStore
end),
TeamUpgradeMeta=safeRequire("TeamUpgradeMeta",function()
return ab"TEAM_UPGRADE_META"
end),
UILayers=safeRequire("UILayers",function()
return require(n.rbxts_include.node_modules["@easy-games"]["game-core"].out).UILayers
end),
VisualizerUtils=safeRequire("VisualizerUtils",function()
return require(s.PlayerScripts.TS.lib.visualizer["visualizer-utils"]).VisualizerUtils
end),
WeldTable=safeRequire("WeldTable",function()
return require(n.TS.util["weld-util"]).WeldUtil
end),
WinEffectMeta=safeRequire("WinEffectMeta",function()
return require(n.TS.locker["win-effect"]["win-effect-meta"]).WinEffectMeta
end),
ZapNetworking=safeRequire("ZapNetworking",function()
return require(s.PlayerScripts.TS.lib.network)
end),
},{
__index=function(aj,ak)
if ak=="BowConstantsTable"then
local Z=safeRequire("BowConstantsTable",function()
return getupvalue(ad.Controllers.ProjectileController.enableBeam,8)
end)
rawset(aj,ak,Z)
return Z
elseif ak=="ItemMeta"then
local Z=safeRequire("ItemMeta",function()
return getupvalue(require(n.TS.item["item-meta"]).getItemMeta,1)
end)
rawset(aj,ak,Z)
return Z
end

local Z=safeRequire(ak,function()
return ad.Controllers[ak]
end)
rawset(aj,ak,Z)
return Z
end,
})















































































































M=setmetatable({
AfkStatus="AfkInfo",
DropItem="DropItem",
BeePickup="PickUpBee",
CannonAim="AimCannon",
GroundHit="GroundHit",
EquipItem="SetInvItem",
DragonFly="DragonFlap",
AttackEntity="SwordHit",
SpawnRaven="SpawnRaven",
GuitarHeal="PlayGuitar",
ConsumeItem="ConsumeItem",
MiloDisguise="MimicBlock",
HarvestCrop="CropHarvest",
ReportPlayer="ReportPlayer",
PickupItem="PickupItemDrop",
DragonBreath="DragonBreath",
DepositPinata="DepositCoins",
ConsumeBattery="ConsumeBattery",
ConsumeTreeOrb="ConsumeTreeOrb",
FireProjectile="ProjectileFire",
HannahKill="HannahPromptTrigger",
KaliyahPunch="RequestDragonPunch",
WarlockTarget="WarlockLinkTarget",
MinerDig="DestroyPetrifiedPlayer",
ConsumeSoul="ConsumeGrimReaperSoul",
CannonLaunch="LaunchSelfFromCannon",
PickupMetal="CollectCollectableEntity",
SummonerClawAttack="SummonerClawAttackRequest",
},{
__index=function(aj,ak)
warn(debug.traceback(`CRITICAL! Failure finding remote {tostring(ak)}!`))
errorNotification("Vape",`Failure finding remote {tostring(ak)}!`,3)
return ak
end,
})
getgenv().remotes=M

ai=L.BlockController.isBlockBreakable

ag.Get=function(aj,ak)
if type(ak)~="string"then
mprint{ak}
return
end
local Z=ah(aj,ak)

if ak==M.AttackEntity then
return{
instance=Z.instance,
SendToServer=function(_,al,...)
local am,an=pcall(function()
return h:GetPlayerFromCharacter(al.entityInstance)
end)

local ao=al.validate.selfPosition.value
local ap=al.validate.targetPosition.value
F.attackReach=((ao-ap).Magnitude*100)//1/100
F.attackReachUpdate=tick()+1

if G.Enabled or H.Enabled then
al.validate.raycast=al.validate.raycast or{}
al.validate.selfPosition.value+=CFrame.lookAt(ao,ap).LookVector*math.max(
(ao-ap).Magnitude-14.399,
0
)
end

if am and an then
if not select(2,z:get(an))then
return
end
end

return Z:SendToServer(al,...)
end,
}
elseif ak=="StepOnSnapTrap"and J.Enabled then
return{SendToServer=function()end}
end

return Z
end

u:Clean(s:GetAttributeChangedSignal"PlayingAsKits":Connect(function()
shared.isKitEquippedCache={}
c.EquippedKitChanged:Fire()
end))

L.BlockController.isBlockBreakable=function(aj,ak,al)
local am=L.BlockController:getStore():getBlockAt(ak.blockPosition)

if am and am.Name=="bed"then
for an,ao in h:GetPlayers()do
if
am:GetAttribute("Team"..(ao:GetAttribute"Team"or 0).."NoBreak")
and not select(2,z:get(ao))
then
return false
end
end
end

return ai(aj,ak,al)
end

local aj,ak={},{blockHealth=-1,breakingBlockPosition=Vector3.zero}
F.blockPlacer=L.BlockPlacer.new(L.BlockEngine,"wool_white")

local function getBlockHealth(al,am)
local an=L.BlockController:getStore():getBlockData(am)
return(
an and(an:GetAttribute"1"or an:GetAttribute"Health")
or al:GetAttribute"Health"
)
end

local function getBlockHits(al,am)
if not al then
return 0
end
local an=L.ItemMeta[al.Name].block.breakType
local ao=F.tools[an]
ao=ao and L.ItemMeta[ao.itemType].breakBlock[an]or 2
return getBlockHealth(al,L.BlockController:getBlockPosition(am))/ao
end





local function calculatePath(al,am)
if aj[am]then
return unpack(aj[am])
end
local an,ao,ap,Z,_={},{{0,am}},{[am]=0},{},{}

for aq=1,10000 do local
ar, as=next(ao)
if not as then
break
end
table.remove(ao,1)
an[as[2] ]=true

for at,au in N do
au=as[2]+au
if an[au]then
continue
end

local av=getPlacedBlock(au)
if not av or av:GetAttribute"NoBreak"or av==al then
if not av then
Z[as[2] ]=true
end
continue
end

local aw=getBlockHits(av,au)+as[1]
if aw<(ap[au]or math.huge)then
table.insert(ao,{aw,au})
ap[au]=aw
_[au]=as[2]
end
end
end

local aq,ar=math.huge
for as in Z do
if ap[as]<aq then
ar,aq=as,ap[as]
end
end

if ar then
aj[am]={
ar,
aq,
_,
}
return ar,aq,_
end
end

L.placeBlock=function(al,am)
if getItem(am)then
F.blockPlacer.blockType=am
return F.blockPlacer:placeBlock(L.BlockController:getBlockPosition(al))
end
end

L.breakBlock=function(al,am,an,ao)
if s:GetAttribute"DenyBlockBreak"or not x.isAlive or I.Enabled then
return
end
local ap=L.BlockController:getHandlerRegistry():getHandler(al.Name)
local aq,ar,as,at=math.huge

for au,av in(ap and ap:getContainedPositions(al)or{al.Position/3})do
local aw,Z,_=calculatePath(al,av*3)
if aw and Z<aq then
aq,ar,as,at=Z,aw,av*3,_
end
end

if ar then
if(x.character.RootPart.Position-ar).Magnitude>30 then
return
end
local au,av=getPlacedBlock(ar)
if not au then
return
end

if(workspace:GetServerTimeNow()-L.SwordController.lastAttack)>0.4 then
local aw=L.ItemMeta[au.Name].block.breakType
local Z=F.tools[aw]
if Z then
switchItem(Z.tool)
end
end

if ak.blockHealth==-1 or av~=ak.breakingBlockPosition then
ak.blockHealth=getBlockHealth(au,av)
ak.breakingBlockPosition=av
end

L.ClientDamageBlock
:Get"DamageBlock"
:CallServerAsync{
blockRef={blockPosition=av},
hitPosition=ar,
hitNormal=Vector3.FromNormalId(Enum.NormalId.Top),
}
:andThen(function(aw)
if aw then
if aw=="cancelled"then
F.damageBlockFail=tick()+1
return
end

if am then
local Z=(
ak.blockHealth
-(aw=="destroyed"and 0 or getBlockHealth(au,av))
)
ao=ao or L.BlockBreaker.updateHealthbar
ao(
L.BlockBreaker,
{blockPosition=av},
ak.blockHealth,
au:GetAttribute"MaxHealth",
Z,
au
)
ak.blockHealth=math.max(ak.blockHealth-Z,0)

if ak.blockHealth<=0 then
L.BlockBreaker.breakEffect:playBreak(au.Name,av,s)
L.BlockBreaker.healthbarMaid:DoCleaning()
ak.breakingBlockPosition=Vector3.zero
else
L.BlockBreaker.breakEffect:playHit(au.Name,av,s)
end
end

if an then
local Z=L.AnimationUtil:playAnimation(
s,
L.BlockController:getAnimationController():getAssetId(1)
)
L.ViewmodelController:playAnimation(15)
task.wait(0.3)
Z:Stop()
Z:Destroy()
end
end
end)

if am then
return ar,at,as
end
end
end

for al,am in Enum.NormalId:GetEnumItems()do
table.insert(N,Vector3.FromNormalId(am)*3)
end

local function updateStore(al,am)
if al.Bedwars~=am.Bedwars then
F.equippedKit=al.Bedwars.kit~="none"and al.Bedwars.kit or""
L.resolveEquippedKit()
end

if al.Game~=am.Game then
F.matchState=al.Game.matchState
F.queueType=al.Game.queueType or"bedwars_test"
end

if al.Inventory~=am.Inventory then
local an=(al.Inventory and al.Inventory.observedInventory or{inventory={}})
local ao=(am.Inventory and am.Inventory.observedInventory or{inventory={}})
F.inventory=an

if an~=ao then
c.InventoryChanged:Fire()
end

if an.inventory.items~=ao.inventory.items then
c.InventoryAmountChanged:Fire()
F.tools.sword=getSword()
for ap,aq in{"stone","wood","wool"}do
F.tools[aq]=getTool(aq)
end
end

if an.inventory.hand~=ao.inventory.hand then
local ap,aq=al.Inventory.observedInventory.inventory.hand,""
if ap then
local ar=L.ItemMeta[ap.itemType]
aq=ar.sword and"sword"
or ar.block and"block"
or ap.itemType:find"bow"and"bow"
end

F.hand={
tool=ap and ap.tool,
amount=ap and ap.amount or 0,
toolType=aq,
}
end
end
end

local al=L.Store.changed:connect(updateStore)
updateStore(L.Store:getState(),{})

for am,an in
{
"MatchEndEvent",
"EntityDeathEvent",
"BedwarsBedBreak",
"BalloonPopped",
"AngelProgress",
"GrapplingHookFunctions",
}
do
if not u.Connections then
return
end
L.Client:WaitFor(an):andThen(function(ao)
u:Clean(ao:Connect(function(...)
c[an]:Fire(...)
end))
end)
end

u:Clean(L.ZapNetworking.EntityDamageEventZap.On(function(...)
c.EntityDamageEvent:Fire{
entityInstance=...,
damage=select(2,...),
damageType=select(3,...),
fromPosition=select(4,...),
fromEntity=select(5,...),
knockbackMultiplier=select(6,...),
knockbackId=select(7,...),
disableDamageHighlight=select(13,...),
}
end))

for am,an in{"PlaceBlockEvent","BreakBlockEvent"}do
u:Clean(L.ZapNetworking[an.."Zap"].On(function(...)
local ao={
blockRef={
blockPosition=...,
},
player=select(5,...),
}
for ap,aq in aj do
if((ao.blockRef.blockPosition*3)-aq[1]).Magnitude<=30 then
table.clear(aq[3])
table.clear(aq)
aj[ap]=nil
end
end
c[an]:Fire(ao)
end))
end

F.blocks=collection("block",gui)
F.shop=collection({"BedwarsItemShop","TeamUpgradeShopkeeper"},gui,function(am,an)
table.insert(am,{
Id=an.Name,
RootPart=an,
Shop=an:HasTag"BedwarsItemShop",
Upgrades=an:HasTag"TeamUpgradeShopkeeper",
})
end)
F.enchant=collection({"enchant-table","broken-enchant-table"},gui,nil,function(am,an,ao)
if an:HasTag"enchant-table"and ao=="broken-enchant-table"then
return
end
an=table.find(am,an)
if an then
table.remove(am,an)
end
end)

local am=C:AddItem"Kills"
local an=C:AddItem"Beds"
local ao=C:AddItem"Wins"
local ap=C:AddItem"Games"

local aq="Unknown"
C:AddItem("Map",0,function()
return aq
end,false)

task.delay(1,function()
ap:Increment()
end)

task.spawn(function()
pcall(function()
repeat
task.wait()
until F.matchState~=0 or u.Loaded==nil
if u.Loaded==nil then
return
end
aq=workspace:WaitForChild("Map",5):WaitForChild("Worlds",5):GetChildren()[1].Name
aq=string.gsub(string.split(aq,"_")[2]or aq,"-","")or"Blank"
end)
end)

u:Clean(c.BedwarsBedBreak.Event:Connect(function(ar)
if ar.player and ar.player.UserId==s.UserId then
an:Increment()
end
end))

u:Clean(c.MatchEndEvent.Event:Connect(function(ar)
if(L.Store:getState().Game.myTeam or{}).id==ar.winningTeamId or s.Neutral then
ao:Increment()
end
end))

u:Clean(c.EntityDeathEvent.Event:Connect(function(ar)
local as=h:GetPlayerFromCharacter(ar.fromEntity)
local at=h:GetPlayerFromCharacter(ar.entityInstance)
if not at or not as then
return
end

if at~=s and as==s then
am:Increment()
end
end))

task.spawn(function()
repeat
if x.isAlive then
x.character.AirTime=x.character.Humanoid.FloorMaterial~=Enum.Material.Air and tick()
or x.character.AirTime
end

for ar,as in x.List do
as.LandTick=math.abs(as.RootPart.Velocity.Y)<0.1 and as.LandTick or tick()
if(tick()-as.LandTick)>0.2 and as.Jumps~=0 then
as.Jumps=0
as.Jumping=false
end
end
task.wait()
until u.Loaded==nil
end)

pcall(function()
if getthreadidentity and setthreadidentity then
local ar=getthreadidentity()
setthreadidentity(2)

L.Shop=require(n.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop

L.ShopItems=L.Shop.ShopItems
setthreadidentity(ar)
F.shopLoaded=true




task.defer(function()
pcall(function()
local as=getthreadidentity()
setthreadidentity(2)
L.Shop.getShopItem("iron_sword",s)
setthreadidentity(as)
end)
end)
else
task.spawn(function()
repeat
task.wait(0.1)
until u.Loaded==nil or L.AppController:isAppOpen"BedwarsItemShopApp"

L.Shop=require(n.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop
L.ShopItems=L.Shop.ShopItems
F.shopLoaded=true

task.defer(function()
pcall(function()
L.Shop.getShopItem("iron_sword",s)
end)
L.TeamUpgradeMeta=safeRequire("TeamUpgradeMeta",function()
return ab"TEAM_UPGRADE_META"
end)
end)
end)
end
end)

u:Clean(function()
ag.Get=ah
L.BlockController.isBlockBreakable=ai
F.blockPlacer:disable()
for ar,as in c do
as:Destroy()
end
for ar,as in aj do
table.clear(as[3])
table.clear(as)
end
table.clear(F.blockPlacer)
table.clear(c)
table.clear(L)
table.clear(F)
table.clear(aj)
table.clear(N)
table.clear(M)
al:disconnect()
al=nil
end)
end,{
name="Internal | Bedwars",
})
if not L.Client then
error"Bedwars.Client missing!"
return
end

for ac,ad in
{
"AntiRagdoll",
"TriggerBot",
"SilentAim",
"AutoRejoin",
"Rejoin",
"Disabler",
"Timer",
"ServerHop",
"MouseTP",
"MurderMystery",
}
do
u:Remove(ad)
end
b(function()
local ac=game:GetService"Players"
function getColor3FromDecimal(ad)
if not ad then
return false
end
local ae=math.floor(ad/(65536))%256
local af=math.floor(ad/256)%256
local ag=ad%256

return Color3.new(ae/255,af/255,ag/255)
end
u:Clean(c.EntityDeathEvent.Event:Connect(function(ad)
local ae=h:GetPlayerFromCharacter(ad.fromEntity)
local af=h:GetPlayerFromCharacter(ad.entityInstance)
if not af or not ae then
return
end
shared.custom_notify("kill",ae,af,ad.finalKill)
end))
u:Clean(c.BedwarsBedBreak.Event:Connect(function(ad)
if
not(
ad~=nil
and type(ad)=="table"
and ad.brokenBedTeam~=nil
and type(ad.brokenBedTeam)=="table"
and ad.brokenBedTeam.id~=nil
)
then
return
end
local ae=L.QueueMeta[F.queueType].teams[tonumber(ad.brokenBedTeam.id)]
local af=ac:GetPlayerByUserId(tonumber(ad.player.UserId))or{Name="Unknown player"}
if not af then
af="Unknown player"
end
shared.custom_notify("bedbreak",af,nil,nil,{
Name=ae and ae.displayName:upper()or"WHITE",
Color=ae and ae.colorHex and getColor3FromDecimal(tonumber(ae.colorHex))
or Color3.fromRGB(255,255,255),
})
end))
u:Clean(c.MatchEndEvent.Event:Connect(function(ad)
local ae=L.QueueMeta[F.queueType].teams[tonumber(ad.winningTeamId)]
if ad.winningTeamId==s:GetAttribute"Team"then
shared.custom_notify("win",nil,nil,false,{
Name=ae and ae.displayName:upper()or"WHITE",
Color=ae and ae.colorHex and getColor3FromDecimal(tonumber(ae.colorHex))
or Color3.fromRGB(255,255,255),
})
else
shared.custom_notify("defeat",nil,nil,false,{
Name=ae and ae.displayName:upper()or"WHITE",
Color=ae and ae.colorHex and getColor3FromDecimal(tonumber(ae.colorHex))
or Color3.fromRGB(255,255,255),
})
end
end))
end)

b(function()
local ac
local ad
local ae
local af
local ag
local ah
local ai
local aj
local ak
local al
local am

local function isFirstPerson()
if not(s.Character and s.Character:FindFirstChild"Head")then
return nil
end
return(s.Character.Head.Position-r.CFrame.Position).Magnitude<2
end

ac=u.Categories.Combat:CreateModule{
Name="AimAssist",
Function=function(an)
if an then
ac:Clean(e.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(ao)
if
x.isAlive
and F.hand.toolType=="sword"
and((not ak.Enabled)or(tick()-L.SwordController.lastSwing)<0.4)
then
local ap=not aj.Enabled
and x.EntityPosition{
Range=ag.Value,
Part="RootPart",
Wallcheck=ad.Walls.Enabled,
Players=ad.Players.Enabled,
NPCs=ad.NPCs.Enabled,
Sort=V[ae.Value],
}
or F.KillauraTarget

if ap then
local aq=(ap.RootPart.Position-x.character.RootPart.Position)
local ar=x.character.RootPart.CFrame.LookVector*Vector3.new(1,0,1)
local as=math.acos(ar:Dot((aq*Vector3.new(1,0,1)).Unit))
if am.Enabled then
if not isFirstPerson()then
return
end
end
if al.Enabled then
local at=s:FindFirstChild"PlayerGui"
and s:FindFirstChild"PlayerGui":FindFirstChild"ItemShop"
or nil
if at then
return
end
end
if ap~=F.KillauraTarget and as>=(math.rad(ah.Value)/2)then
return
end
A.Targets[ap]=tick()+1
r.CFrame=r.CFrame:Lerp(
CFrame.lookAt(r.CFrame.p,ap.RootPart.Position),
(
af.Value
+(
ai.Enabled
and(k:IsKeyDown(Enum.KeyCode.A)or k:IsKeyDown(
Enum.KeyCode.D
))
and 10
or 0
)
)*ao
)
end
end
end)))
end
end,
Tooltip="Smoothly aims to closest valid target with sword",
}
ad=ac:CreateTargets{
Players=true,
Walls=true
}
local an={"Damage","Distance"}
for ao in V do
if not table.find(an,ao)then
table.insert(an,ao)
end
end
ae=ac:CreateDropdown{
Name="Target Mode",
List=an,
}
af=ac:CreateSlider{
Name="Aim Speed",
Min=1,
Max=20,
Default=6,
}
ag=ac:CreateSlider{
Name="Distance",
Min=1,
Max=30,
Default=30,
Suffx=function(ao)
return ao==1 and"stud"or"studs"
end,
}
ah=ac:CreateSlider{
Name="Max angle",
Min=1,
Max=360,
Default=70,
}
ak=ac:CreateToggle{
Name="Click Aim",
Default=true,
}
aj=ac:CreateToggle{
Name="Use killaura target",
}
al=ac:CreateToggle{
Name="Shop Check",
Function=function()end,
Default=false,
}
am=ac:CreateToggle{
Name="First Person Check",
Function=function()end,
Default=false,
}
ai=ac:CreateToggle{Name="Strafe increase"}
end)

b(function()
local ac
local ad
local ae={}
local af
local ag
local ah=false

local ai=k.TouchEnabled and not k.KeyboardEnabled


local aj=RaycastParams.new()
aj.FilterType=Enum.RaycastFilterType.Exclude
local function getCrosshairBlockPos()
if not x.isAlive then
return nil
end
aj.FilterDescendantsInstances={s.Character,r}
local ak=workspace:Raycast(r.CFrame.Position,r.CFrame.LookVector*50,aj)
if ak then
return roundPos(ak.Position+ak.Normal*1.5)
end
return nil
end

local function doBlockPlace()
if not x.isAlive then
return
end
if L.AppController:isLayerOpen(L.UILayers.MAIN)then
return
end
if F.hand.toolType~="block"then
return
end
local ak=F.hand.tool.Name
if ai then
local al=getCrosshairBlockPos()
if al and not getPlacedBlock(al)then
task.spawn(L.placeBlock,al,ak)
end
else
local al=L.BlockPlacementController.blockPlacer
if al then
if
(workspace:GetServerTimeNow()-L.BlockCpsController.lastPlaceTimestamp)>=(4.1666666666666664E-2)
then
local am=al.clientManager:getBlockSelector():getMouseInfo(0)
if am and am.placementPosition==am.placementPosition then
task.spawn(al.placeBlock,al,am.placementPosition)
end
end
end
end
end


local function AutoClick()
if af then
task.cancel(af)
end
af=task.delay(0.14285714285714285,function()
repeat
if not L.AppController:isLayerOpen(L.UILayers.MAIN)then
if F.hand.toolType=="sword"then
L.SwordController:swingSwordAtMouse(0.39)
end

end
task.wait(1/ad.GetRandomValue())
until not ac.Enabled and not ah
end)
end


local function startBlockSpam()
if ag then
task.cancel(ag)
end
ag=task.spawn(function()
repeat
if not L.AppController:isLayerOpen(L.UILayers.MAIN)then
doBlockPlace()
end
task.wait(1/ae.GetRandomValue())
until not ac.Enabled
end)
end

local function stopBlockSpam()
if ag then
task.cancel(ag)
ag=nil
end
end

ac=u.Categories.Combat:CreateModule{
Name="AutoClicker",
Function=function(ak)
if ak then




ac:Clean(k.InputBegan:Connect(function(al)
if al.UserInputType==Enum.UserInputType.MouseButton1 then
if F.hand and F.hand.toolType=="block"then
startBlockSpam()
else
AutoClick()
end
end
end))
ac:Clean(k.InputEnded:Connect(function(al)
if al.UserInputType==Enum.UserInputType.MouseButton1 then

stopBlockSpam()
if af then
task.cancel(af)
af=nil
end
end
end))

if ai then
task.spawn(function()
local al=pcall(function()
local al=s.PlayerGui:WaitForChild("MobileUI",5)
if al then
local am=al:FindFirstChild"2"
if am then

ac:Clean(am.InputBegan:Connect(function(an)
if
an.UserInputType==Enum.UserInputType.Touch
or an.UserInputType==Enum.UserInputType.MouseButton1
then
if F.hand and F.hand.toolType~="block"then
ah=true
AutoClick()
end
end
end))
ac:Clean(am.InputEnded:Connect(function(an)
if
an.UserInputType==Enum.UserInputType.Touch
or an.UserInputType==Enum.UserInputType.MouseButton1
then
ah=false
if af then
task.cancel(af)
af=nil
end
end
end))
end




local function hookBlockButton()
local an=s.PlayerGui
local ao=an:FindFirstChild"ActionBarScreenGui"
and an.ActionBarScreenGui:FindFirstChild"ActionBar"
if not ao then
return
end
local ap=ao:FindFirstChild"ActionButton"
if not ap then
return
end
ac:Clean(ap.InputBegan:Connect(function(aq)
if
aq.UserInputType==Enum.UserInputType.Touch
or aq.UserInputType==Enum.UserInputType.MouseButton1
then
if F.hand and F.hand.toolType=="block"then
startBlockSpam()
end
end
end))
ac:Clean(ap.InputEnded:Connect(function(aq)
if
aq.UserInputType==Enum.UserInputType.Touch
or aq.UserInputType==Enum.UserInputType.MouseButton1
then
stopBlockSpam()
end
end))
end

if not pcall(hookBlockButton)then
ac:Clean(s.PlayerGui.ChildAdded:Connect(function()
pcall(hookBlockButton)
end))
end
end
end)
if not al then
warn"AutoClicker: Failed to setup mobile buttons"
end
end)
end
else
ah=false
stopBlockSpam()
if af then
task.cancel(af)
af=nil
end
end
end,
Tooltip="Hold attack button to sword-spam. Hold place block button to block-spam.",
}

ad=ac:CreateTwoSlider{
Name="CPS",
Min=1,
Max=9,
DefaultMin=7,
DefaultMax=7,
}

ac:CreateToggle{
Name="Place Blocks",
Default=true,
Function=function(ak)
if ae.Object then
ae.Object.Visible=ak
end
end,
}

ae=ac:CreateTwoSlider{
Name="Block CPS",
Min=1,
Max=12,
DefaultMin=12,
DefaultMax=12,
Darker=true,
}
end)

b(function()
local ac

u.Categories.Combat:CreateModule{
Name="NoClickDelay",
Function=function(ad)
if ad then
ac=L.SwordController.isClickingTooFast
L.SwordController.isClickingTooFast=function(ae)
ae.lastSwing=os.clock()
return false
end
else
L.SwordController.isClickingTooFast=ac
end
end,
Tooltip="Remove the CPS cap",
}
end)

b(function()
local ac,ad,ae

local af

G=u.Categories.Combat:CreateModule{
Name="Reach",
Tooltip="Extends reach for attacking, mining & placing",
Function=function(ag)
if ag then
oldAttackReach=L.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE

pcall(function()
local ah=L.BlockBreakController:getBlockBreaker()
if ah then
oldMineReach=ah:getRange()
end
end)

af=af or L.BlockBreaker.clientManager:getBlockSelector().getMouseInfo

L.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE=ac.Value+2

L.BlockBreaker.clientManager:getBlockSelector().getMouseInfo=function(ah,ai,aj)
aj=aj or{}
aj.range=ae.Value
return af(ah,ai,aj)
end

task.spawn(function()
repeat
task.wait()
until L.BlockBreakController or not G.Enabled
if not G.Enabled then
return
end

pcall(function()
local ah=L.BlockBreakController:getBlockBreaker()
if ah then
ah:setRange(ad.Value)
end
end)
end)

task.spawn(function()
while G.Enabled do
if L.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE~=ac.Value+2 then
L.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE=ac.Value+2
end

pcall(function()
local ah=L.BlockBreakController:getBlockBreaker()
if ah and ah:getRange()~=ad.Value then
ah:setRange(ad.Value)
end
end)

task.wait(0.4)
end
end)
else
L.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE=oldAttackReach or 14.4

pcall(function()
local ah=L.BlockBreakController:getBlockBreaker()
if ah then
ah:setRange(oldMineReach or 18)
end
end)

if af then
L.BlockBreaker.clientManager:getBlockSelector().getMouseInfo=af
end

oldAttackReach=nil
oldMineReach=nil
end
end,
}

ac=G:CreateSlider{
Name="Attack Range",
Min=0,
Max=20,
Default=18,
Function=function(ag)
if G.Enabled then
L.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE=ag+2
end
end,
Suffix=function(ag)
return ag==1 and"stud"or"studs"
end,
}

ae=G:CreateSlider{
Name="Place Range",
Min=0,
Max=40,
Default=18,
Function=function(ag)
if G.Enabled then
L.BlockBreaker.clientManager:getBlockSelector().getMouseInfo=function(ah,ai,aj)
aj=aj or{}
aj.range=ag
return af(ah,ai,aj)
end
end
end,
Suffix=function(ag)
return ag==1 and"stud"or"studs"
end,
}

ad=G:CreateSlider{
Name="Mine Range",
Min=0,
Max=30,
Default=18,
Function=function(ag)
if G.Enabled then
pcall(function()
local ah=L.BlockBreakController:getBlockBreaker()
if ah then
ah:setRange(ag)
end
end)
end
end,
Suffix=function(ag)
return ag==1 and"stud"or"studs"
end,
}
end)

b(function()
local ac
local ad

ac=u.Categories.Combat:CreateModule{
Name="Sprint",
Function=function(ae)
if ae then
if k.TouchEnabled then
pcall(function()
s.PlayerGui.MobileUI["4"].Visible=false
end)
end
ad=L.SprintController.stopSprinting
L.SprintController.stopSprinting=function(...)
local af=ad(...)
L.SprintController:startSprinting()
return af
end
ac:Clean(x.Events.LocalAdded:Connect(function()
task.delay(0.1,function()
L.SprintController:stopSprinting()
end)
end))
L.SprintController:stopSprinting()
else
if k.TouchEnabled then
pcall(function()
s.PlayerGui.MobileUI["4"].Visible=true
end)
end
L.SprintController.stopSprinting=ad
L.SprintController:stopSprinting()
end
end,
Tooltip="Sets your sprinting to true.",
}
end)

b(function()
local ac
local ad
local ae=RaycastParams.new()

ac=u.Categories.Combat:CreateModule{
Name="TriggerBot",
Function=function(af)
if af then
repeat
local ag
if not L.AppController:isLayerOpen(L.UILayers.MAIN)then
if
x.isAlive
and F.hand.toolType=="sword"
and L.DaoController.chargingMaid==nil
then
local ah=L.ItemMeta[F.hand.tool.Name].sword.attackRange
ae.FilterDescendantsInstances={s.Character}

local ai=s:GetMouse().UnitRay
local aj=x.character.RootPart.Position
local ak=(ah or 14.4)
local al=L.QueryUtil:raycast(ai.Origin,ai.Direction*200,ae)
if al and(aj-al.Instance.Position).Magnitude<=ak then

for am,an in x.List do
ag=an.Targetable
and al.Instance:IsDescendantOf(an.Character)
and(aj-an.RootPart.Position).Magnitude<=ak
if ag then
break
end
end
end

ag=ag or L.SwordController:getTargetInRegion(ah or 11.399999999999999,0)
if ag then
L.SwordController:swingSwordAtMouse()
end
end
end

task.wait(ag and 1/ad.GetRandomValue()or 0.016)
until not ac.Enabled
end
end,
Tooltip="Automatically swings when hovering over a entity",
}
ad=ac:CreateTwoSlider{
Name="CPS",
Min=1,
Max=9,
DefaultMin=7,
DefaultMax=7,
}
end)

b(function()
local ac
local ad
local ae
local af
local ag
local ah,ai=Random.new()

ac=u.Categories.Combat:CreateModule{
Name="Velocity",
Function=function(aj)
if aj then
ai=L.KnockbackUtil.applyKnockback
L.KnockbackUtil.applyKnockback=function(ak,al,am,an,...)
if ah:NextNumber(0,100)>af.Value then
return
end
local ao=not ag.Enabled
or x.EntityPosition{
Range=50,
Part="RootPart",
Players=true,
}

if ao then
an=an or{}
if ad.Value==0 and ae.Value==0 then
return
end
an.horizontal=(an.horizontal or 1)*(ad.Value/100)
an.vertical=(an.vertical or 1)*(ae.Value/100)
end

return ai(ak,al,am,an,...)
end
else
L.KnockbackUtil.applyKnockback=ai
end
end,
Tooltip="Reduces knockback taken",
}
ad=ac:CreateSlider{
Name="Horizontal",
Min=0,
Max=100,
Default=0,
Suffix="%",
}
ae=ac:CreateSlider{
Name="Vertical",
Min=0,
Max=100,
Default=0,
Suffix="%",
}
af=ac:CreateSlider{
Name="Chance",
Min=0,
Max=100,
Default=100,
Suffix="%",
}
ag=ac:CreateToggle{Name="Only when targeting"}
end)

F.RAYCAST_BLACKLISTED={
objs={},
add=function(ac,ad)
if not table.find(ac.objs,ad)and ad.Parent~=nil then
table.insert(ac.objs,ad)
ad.Destroying:Once(function()
ac:remove(ad)
end)
end
end,
remove=function(ac,ad)
local ae=table.find(ac.objs,ad)
if ae then
table.remove(ac.objs,ae)
end
end,
}









local function blocksRaycast(ac)
local ad=s.Character
if not s.Character then
return false
end
local ae=ad.PrimaryPart
if ae~=nil then
ae=ae.Position
end
if not ae then
return false
end
local af=RaycastParams.new()
af.CollisionGroup="Blocks"
af.FilterType=Enum.RaycastFilterType.Exclude
af.IgnoreWater=true
local ag=0
local ah={r,workspace:FindFirstChild"Terrain"}
ag=#ah
for ai,aj in Players:GetPlayers()do
local ak=aj.Character
if ak~=nil then
ag=ag+1
ah[ag]=ak
end
end
for ai,aj in(F.RAYCAST_BLACKLISTED.objs or{})do
ag=ag+1
ah[ag]=aj
end
af.FilterDescendantsInstances=ah
if not ac or type(ac)=="number"then
local ai=ac or 400
ai=-ai
ac=Vector3.new(0,ai,0)
end
return workspace:Raycast(ae,ac,af)
end
global().blocksRaycast=blocksRaycast

local ac
b(function()
local ad
local ae
local af
local ag
local ah=RaycastParams.new()
ah.RespectCanCollide=true

local function getLowGround()
local ai=math.huge
for aj,ak in L.BlockController:getStore():getAllBlockPositions()do
ak=ak*3
if ak.Y<ai and not getPlacedBlock(ak+Vector3.new(0,3,0))then
ai=ak.Y
end
end
return ai
end

ad=u.Categories.Blatant:CreateModule{
Name="AntiFall",
Function=function(ai)
if ai then
repeat
task.wait()
until F.matchState~=0 or not ad.Enabled
if not ad.Enabled then
return
end

local aj,ak=getLowGround(),tick()
if aj~=math.huge then
K=Instance.new"Part"
K.Size=Vector3.new(10000,1,10000)
K.Transparency=1-ag.Opacity
K.Material=Enum.Material[af.Value]
K.Color=Color3.fromHSV(ag.Hue,ag.Sat,ag.Value)
K.Position=Vector3.new(0,aj-2,0)
K.CanCollide=ae.Value=="Collide"
K.Anchored=true
K.CanQuery=false
K.Parent=workspace
F.RAYCAST_BLACKLISTED:add(K)
ad:Clean(K)
ad:Clean(K.Touched:Connect(function(al)
if al.Parent==s.Character and x.isAlive and ak<tick()then
ak=tick()+0.1
if ae.Value=="Normal"then
local am=getNearGround()
if am then
local an=s:GetAttribute"LastTeleported"
local ao
ao=e.PreSimulation:Connect(LPH_NO_VIRTUALIZE(function()
if
u.Modules.Fly.Enabled
or u.Modules.InfiniteFly.Enabled
or u.Modules.LongJump.Enabled
then
ao:Disconnect()
ac=nil
return
end

if
x.isAlive
and s:GetAttribute"LastTeleported"==an
then
local ap=(
(am-x.character.RootPart.Position)*Vector3.new(1,0,1)
)
local aq=x.character.RootPart
ac=ap.Unit==ap.Unit and ap.Unit or Vector3.zero
aq.Velocity*=Vector3.new(1,0,1)
ah.FilterDescendantsInstances={r,s.Character}
ah.CollisionGroup=aq.CollisionGroup

local ar=blocksRaycast(ac)

if ar then
for as=1,10 do
local at=roundPos(ar.Position+ar.Normal*1.5)
+Vector3.new(0,3,0)
if not getPlacedBlock(at)then
am=Vector3.new(am.X,aj.Y,am.Z)
break
end
end
end

aq.CFrame+=Vector3.new(0,am.Y-aq.Position.Y,0)
if not Q.Speed then
aq.AssemblyLinearVelocity=(ac*getSpeed())
+Vector3.new(0,aq.AssemblyLinearVelocity.Y,0)
end

if ap.Magnitude<1 then
ao:Disconnect()
ac=nil
end
else
ao:Disconnect()
ac=nil
end
end))
ad:Clean(ao)
end
elseif ae.Value=="Velocity"then
x.character.RootPart.Velocity=Vector3.new(
x.character.RootPart.Velocity.X,
100,
x.character.RootPart.Velocity.Z
)
end
end
end))
end
else
ac=nil
end
end,
Tooltip="Help's you with your Parkinson's\nPrevents you from falling into the void.",
}
ae=ad:CreateDropdown{
Name="Move Mode",
List={"Normal","Collide","Velocity"},
Function=function(ai)
if K then
K.CanCollide=ai=="Collide"
end
end,
Tooltip="Normal - Smoothly moves you towards the nearest safe point\nVelocity - Launches you upward after touching\nCollide - Allows you to walk on the part",
}
local ai={"ForceField"}
for aj,ak in Enum.Material:GetEnumItems()do
if ak.Name~="ForceField"then
table.insert(ai,ak.Name)
end
end
af=ad:CreateDropdown{
Name="Material",
List=ai,
Function=function(aj)
if K then
K.Material=Enum.Material[aj]
end
end,
}
ag=ad:CreateColorSlider{
Name="Color",
DefaultOpacity=0.5,
Function=function(aj,ak,al,am)
if K then
K.Color=Color3.fromHSV(aj,ak,al)
K.Transparency=1-am
end
end,
}
end)

b(function()
local ad
local ae

ad=u.Categories.Blatant:CreateModule{
Name="FastBreak",
Function=function(af)
if af then
repeat
L.BlockBreakController.blockBreaker:setCooldown(ae.Value)
task.wait(0.1)
until not ad.Enabled
else
L.BlockBreakController.blockBreaker:setCooldown(0.3)
end
end,
Tooltip="Decreases block hit cooldown",
}
ae=ad:CreateSlider{
Name="Break speed",
Min=0,
Max=0.3,
Default=0.25,
Decimal=100,
Suffix="seconds",
}
end)

local ad
local ae
b(function()
local af
local ag
local ah
local ai
local aj
local ak

local al
local am=RaycastParams.new()
am.RespectCanCollide=true
local an,ao,ap=0,0

local aq={}

local function createMobileButton(ar,as,at)
local au=Instance.new"TextButton"

au.Name=ar
au.Size=UDim2.new(0,60,0,60)
au.Position=as
au.BackgroundColor3=Color3.fromRGB(30,30,30)
au.BackgroundTransparency=0.3
au.BorderSizePixel=0
au.Text=at
au.TextColor3=Color3.fromRGB(255,255,255)
au.TextScaled=true
au.FontFace=Font.new("SourceSansPro",Enum.FontWeight.Bold)
au.AutoButtonColor=false

local av=Instance.new"UICorner"
av.CornerRadius=UDim.new(0,12)
av.Parent=au

return au
end

local function cleanupMobileControls()
for ar,as in pairs(aq)do
if as and as.Parent then
as:Destroy()
end
end
aq={}
end

local function setupMobileControls()
cleanupMobileControls()

local ar=u.gui

local as=createMobileButton("UpButton",UDim2.new(0.9,-70,0.5,-100),"↑")

local at=createMobileButton("DownButton",UDim2.new(0.9,-70,0.5,-20),"↓")

aq.UpButton=as
aq.DownButton=at

as.Parent=ar
at.Parent=ar

return as,at
end

local function cleanProgressBar()
if al~=nil and al.Parent~=nil then
al:Destroy()
end
al=nil
end

local function createProgressBar()
pcall(cleanProgressBar)
al=Instance.new"Frame"
al.AnchorPoint=Vector2.new(0.5,0)
al.Position=UDim2.new(0.5,0,1,-200)
al.Size=UDim2.new(0.2,0,0,20)
al.BackgroundTransparency=0.5
al.BorderSizePixel=0
al.BackgroundColor3=Color3.new(0,0,0)
al.Visible=ad.Enabled
al.Parent=u.gui
local ar=al:Clone()
ar.AnchorPoint=Vector2.new(0,0)
ar.Position=UDim2.new(0,0,0,0)
ar.Size=UDim2.new(1,0,0,20)
ar.BackgroundTransparency=0
ar.Visible=true
ar.Parent=al
local as=Instance.new"TextLabel"
as.Text="2s"
as.Font=Enum.Font.Gotham
as.TextStrokeTransparency=0
as.TextColor3=Color3.new(0.9,0.9,0.9)
as.TextSize=20
as.Size=UDim2.new(1,0,1,0)
as.BackgroundTransparency=1
as.Position=UDim2.new(0,0,-1,0)
as.Parent=al
return u.connectguicolorchange(function(at,au,av)
if al~=nil and al.Parent~=nil then
al.BackgroundColor3=Color3.fromHSV(at,au,av)
if ar~=nil and ar.Parent~=nil then
ar.BackgroundColor3=Color3.fromHSV(at,au,av)
end
end
end)
end

ad=u.Categories.Blatant:CreateModule{
Name="Fly",
Function=function(ar)
Q.Fly=ar or nil
updateVelocity()
if ar then
an,ao,ap=0,0,L.BalloonController.deflateBalloon
L.BalloonController.deflateBalloon=function()end
local as,at,au=tick(),true

if
s.Character
and(s.Character:GetAttribute"InflatedBalloons"or 0)==0
and getItem"balloon"
then
L.BalloonController:inflateBalloon()
end

if ak.Enabled then
local av,aw=pcall(createProgressBar)
if av and aw~=nil then
ad:Clean(createProgressBar)
else
errorNotification("Fly",`Couldn't create Progress Bar -> {tostring(aw)}`,5)
warn(`[Fly - ProgressBar]: {tostring(aw)}`)
end
end

ad:Clean(k.InputBegan:Connect(function(av)
if k:GetFocusedTextBox()==nil then
if av.KeyCode==Enum.KeyCode.Space or av.KeyCode==Enum.KeyCode.ButtonA then
an=1
end
if av.KeyCode==Enum.KeyCode.LeftShift or av.KeyCode==Enum.KeyCode.ButtonL2 then
ao=-1
end
end
end))
ad:Clean(k.InputEnded:Connect(function(av)
if av.KeyCode==Enum.KeyCode.Space or av.KeyCode==Enum.KeyCode.ButtonA then
an=0
end
if av.KeyCode==Enum.KeyCode.LeftShift or av.KeyCode==Enum.KeyCode.ButtonL2 then
ao=0
end
end))

local av=k.TouchEnabled
and not k.KeyboardEnabled
and not k.MouseEnabled
if FlyMobileButtons.Enabled or av then
local aw,Z=setupMobileControls()

ad:Clean(aw.MouseButton1Down:Connect(function()
an=1
end))
ad:Clean(aw.MouseButton1Up:Connect(function()
an=0
end))
ad:Clean(Z.MouseButton1Down:Connect(function()
ao=-1
end))
ad:Clean(Z.MouseButton1Up:Connect(function()
ao=0
end))
end

ad:Clean(c.AttributeChanged.Event:Connect(function(aw)
if
aw=="InflatedBalloons"
and(s.Character:GetAttribute"InflatedBalloons"or 0)==0
and getItem"balloon"
then
L.BalloonController:inflateBalloon()
end
end))
ad:Clean(e.PreSimulation:Connect(LPH_NO_VIRTUALIZE(function(aw)
if
x.isAlive
and not I.Enabled
and q(x.character.RootPart)
then
local Z=(
s.Character:GetAttribute"InflatedBalloons"
and s.Character:GetAttribute"InflatedBalloons">0
)or F.matchState==2
local _=(1.5+(Z and 6 or 0)*(tick()%0.4<0.2 and-1 or 1))
+((an+ao)*ag.Value)
local ax,ay=
x.character.RootPart,x.character.Humanoid.MoveDirection
local az=getSpeed()
local aA=(ay*math.max(af.Value-az,0)*aw)
am.FilterDescendantsInstances={s.Character,r,K}
am.CollisionGroup=ax.CollisionGroup

if ak.Enabled and al~=nil and al.Parent~=nil then
al.Visible=ad.Enabled and not Z
end

if ah.Enabled then
local aB=blocksRaycast(aA)

if aB then
aA=((aB.Position+aB.Normal)-ax.Position)
end
end

if not Z then
if at then
local aB=(tick()-x.character.AirTime)
if
ak.Enabled
and al~=nil
and al.Parent~=nil
then
if al:FindFirstChild"Frame"then
if aB<0.1 then
al.Frame:TweenSize(
UDim2.new(1,0,0,20),
Enum.EasingDirection.InOut,
Enum.EasingStyle.Linear,
0,
true
)
else
al.Frame:TweenSize(
UDim2.new(0,0,0,20),
Enum.EasingDirection.InOut,
Enum.EasingStyle.Linear,
(2.5-aB),
true
)
end
end
if al:FindFirstChild"TextLabel"and aB~=nil then
al.TextLabel.Text=math.max(
aB<0.1 and 2.5 or math.floor((2.5-aB)*10)/10,
0
).."s"
end
end
if aB>2 then
if not au then
local aC=blocksRaycast(1000)

if not aC then
al.Frame:TweenSize(
UDim2.new(0,0,0,20),
Enum.EasingDirection.InOut,
Enum.EasingStyle.Linear,
0,
true
)
end
if aC and aj.Enabled then
at=false
au=ax.Position.Y
as=tick()+0.11
ax.CFrame=CFrame.lookAlong(
Vector3.new(
ax.Position.X,
aC.Position.Y+x.character.HipHeight,
ax.Position.Z
),
ax.CFrame.LookVector
)
end
end
end
else
if au then
if as<tick()then
local aB=Vector3.new(ax.Position.X,au,ax.Position.Z)
ax.CFrame=CFrame.lookAlong(aB,ax.CFrame.LookVector)
at=true
au=nil
else
_=0
end
end
end
end

ax.CFrame+=aA
ax.AssemblyLinearVelocity=(ay*az)+Vector3.new(0,_,0)
end
end)))
ad:Clean(k.InputBegan:Connect(function(aw)
if not k:GetFocusedTextBox()then
if aw.KeyCode==Enum.KeyCode.Space or aw.KeyCode==Enum.KeyCode.ButtonA then
an=1
elseif aw.KeyCode==Enum.KeyCode.LeftShift or aw.KeyCode==Enum.KeyCode.ButtonL2 then
ao=-1
end
end
end))
ad:Clean(k.InputEnded:Connect(function(aw)
if aw.KeyCode==Enum.KeyCode.Space or aw.KeyCode==Enum.KeyCode.ButtonA then
an=0
elseif aw.KeyCode==Enum.KeyCode.LeftShift or aw.KeyCode==Enum.KeyCode.ButtonL2 then
ao=0
end
end))
if k.TouchEnabled then
pcall(function()
local aw=s.PlayerGui.TouchGui.TouchControlFrame.JumpButton
ad:Clean(aw:GetPropertyChangedSignal"ImageRectOffset":Connect(function()
an=aw.ImageRectOffset.X==146 and 1 or 0
end))
end)
end
else
L.BalloonController.deflateBalloon=ap
if
ai.Enabled
and x.isAlive
and(s.Character:GetAttribute"InflatedBalloons"or 0)>0
then
for as=1,3 do
L.BalloonController:deflateBalloon()
end
end
pcall(cleanProgressBar)
pcall(cleanupMobileControls)
end
end,
ExtraText=function()
return"Heatseeker"
end,
Tooltip="Makes you go zoom.",
}

af=ad:CreateSlider{
Name="Speed",
Min=1,
Max=23,
Default=23,
Suffix=function(ar)
return ar==1 and"stud"or"studs"
end,
}
ag=ad:CreateSlider{
Name="Vertical Speed",
Min=1,
Max=150,
Default=50,
Suffix=function(ar)
return ar==1 and"stud"or"studs"
end,
}
ah=ad:CreateToggle{
Name="Wall Check",
Default=true,
}
FlyMobileButtons=ad:CreateToggle{
Name="Mobile Buttons",
Default=m.TouchEnabled and not m.KeyboardEnabled,
Function=function()
if ad.Enabled then
ad:Toggle()
task.wait(0.1)
ad:Toggle()
end
end,
}
ai=ad:CreateToggle{
Name="Pop Balloons",
Default=true,
}
aj=ad:CreateToggle{
Name="TP Down",
Default=true,
}
ak=ad:CreateToggle{
Name="Progress Bar",
Default=true,
Function=function(ar)
if not ar then
pcall(cleanProgressBar)
end
if ad.Enabled then
ad:Toggle()
task.wait(0.1)
ad:Toggle()
end
end,
}
end)

b(function()
local af
local ag
local ah,ai={}

local function createHitbox(aj)
if aj.Targetable and aj.Player then
local ak=Instance.new"Part"
ak.Size=Vector3.new(3,6,3)+Vector3.one*(ag.Value/5)
ak.Position=aj.RootPart.Position
ak.CanCollide=false
ak.Massless=true
ak.Transparency=1
ak.Parent=aj.Character
local al=Instance.new"Motor6D"
al.Part0=ak
al.Part1=aj.RootPart
al.Parent=ak
ah[aj]=ak
end
end

H=u.Categories.Blatant:CreateModule{
Name="HitBoxes",
Function=function(aj)
if aj then
if af.Value=="Sword"then
debug.setconstant(L.SwordController.swingSwordInRegion,6,(ag.Value/3))
ai=true
else
H:Clean(x.Events.EntityAdded:Connect(createHitbox))
H:Clean(x.Events.EntityRemoving:Connect(function(ak)
if ah[ak]then
ah[ak]:Destroy()
ah[ak]=nil
end
end))
for ak,al in x.List do
createHitbox(al)
end
end
else
if ai then
debug.setconstant(L.SwordController.swingSwordInRegion,6,3.8)
ai=nil
end
for ak,al in ah do
al:Destroy()
end
table.clear(ah)
end
end,
Tooltip="Expands attack hitbox",
}
af=H:CreateDropdown{
Name="Mode",
List={"Sword","Player"},
Function=function()
if H.Enabled then
H:Toggle()
H:Toggle()
end
end,
Tooltip="Sword - Increases the range around you to hit entities\nPlayer - Increases the players hitbox",
}
ag=H:CreateSlider{
Name="Expand amount",
Min=0,
Max=14.4,
Default=14.4,
Decimal=10,
Function=function(aj)
if H.Enabled then
if af.Value=="Sword"then
debug.setconstant(L.SwordController.swingSwordInRegion,6,(aj/3))
else
for ak,al in ah do
al.Size=Vector3.new(3,6,3)+Vector3.one*(aj/5)
end
end
end
end,
Suffix=function(aj)
return aj==1 and"stud"or"studs"
end,
}
end)

b(function()
u.Categories.Blatant:CreateModule{
Name="KeepSprint",
Function=function(af)
debug.setconstant(
L.SprintController.startSprinting,
5,
af and"blockSprinting"or"blockSprint"
)
L.SprintController:stopSprinting()
end,
Tooltip="Lets you sprint with a speed potion.",
}
end)

local af
local ag
b(function()
local ah
local ai
local aj
local ak
local al

local am
local an
local ao
local ap
local aq
local ar
local as
local at
local au
local av
local aw
local ax
local ay
local az
local aA
local aB
local aC
local Z
local _
local aD
local aE
local aF={}
local aG,aH={},{}
local aI,aJ,aK,aL=u.Libraries.auraanims,tick()
local aM={FireServer=function()end}
task.spawn(function()
aM=L.Client:Get(M.AttackEntity).instance
end)

local function createRangeCircle()
local aN,aO=pcall(function()
if not shared.CheatEngineMode then
az=Instance.new"MeshPart"
az.MeshId="rbxassetid://3726303797"
u.connectguicolorchange(function(aN,aO,aP)
az.Color=Color3.fromHSV(aN,aO,aP)
end)
az.CanCollide=false
az.Anchored=true
az.Material=Enum.Material.Neon
az.Size=Vector3.new(al.Value*0.7,0.01,al.Value*0.7)
if ah.Enabled then
az.Parent=r
end
az:SetAttribute("gamecore_GameQueryIgnore",true)
end
end)
if not aN then
pcall(function()
if az then
az:Destroy()
az=nil
end
InfoNotification(
"Killaura - Range Visualiser Circle",
"There was an error creating the circle. Disabling...",
2
)
warn(aO)
end)
end
end

local function getAttackData()
if ap.Enabled then
if not k:IsMouseButtonPressed(0)then
return false
end
end

if ar.Enabled then
if L.AppController:isLayerOpen(L.UILayers.MAIN)then
return false
end
end

local aN=aD.Enabled and F.hand or F.tools.sword
if not aN or not aN.tool then
return false
end

local aO=L.ItemMeta[aN.tool.Name]
if aD.Enabled then
if F.hand.toolType~="sword"or L.DaoController.chargingMaid then
return false
end
end

if aF.Enabled then
if(tick()-L.SwordController.lastSwing)>0.2 then
return false
end
end

return aN,aO
end

ah=u.Categories.Blatant:CreateModule{
Name="Killaura",
Function=function(aN)
if aN then
if ay.Enabled then
createRangeCircle()
end
if k.TouchEnabled then
pcall(function()
s.PlayerGui.MobileUI["2"].Visible=aD.Enabled
end)
end

if
aB.Enabled
and not(identifyexecutor and table.find({"Argon","Delta"},({identifyexecutor()})[1]))
then
local aO={
Controllers={
ViewmodelController={
isVisible=function()
return not af
end,
playAnimation=function(...)
if not af then
L.ViewmodelController:playAnimation(select(2,...))
end
end,
},
},
}
debug.setupvalue(P or L.SwordController.playSwordEffect,6,aO)
debug.setupvalue(L.ScytheController.playLocalAnimation,3,aO)

task.spawn(function()
local aP=false
repeat
if af then
if not aL then
aL=r.Viewmodel.RightHand.RightWrist.C0
end
local aQ=not aP
aP=true

if aC.Value=="Random"then
aI.Random={
{
CFrame=CFrame.Angles(
math.rad(math.random(1,360)),
math.rad(math.random(1,360)),
math.rad(math.random(1,360))
),
Time=0.12,
},
}
end

for aR,aS in aI[aC.Value]do
aK=j:Create(
r.Viewmodel.RightHand.RightWrist,
TweenInfo.new(
aQ and(_.Enabled and 0.001 or 0.1)
or aS.Time/Z.Value,
Enum.EasingStyle.Linear
),
{
C0=aL*aS.CFrame,
}
)
aK:Play()
aK.Completed:Wait()
aQ=false
if(not ah.Enabled)or not af then
break
end
end
elseif aP then
aP=false
aK=j:Create(
r.Viewmodel.RightHand.RightWrist,
TweenInfo.new(_.Enabled and 0.001 or 0.3,Enum.EasingStyle.Exponential),
{
C0=aL,
}
)
aK:Play()
end

if not aP then
task.wait(1/am.Value)
end
until(not ah.Enabled)or not aB.Enabled
end)
end
local aO=0
local aP=0
local aQ=a:wrap(function()
pcall(function()
if
az~=nil
and az.Parent~=nil
and x.isAlive
and x.character.HumanoidRootPart
then
j
:Create(
az,
TweenInfo.new(0.2,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),
{
Position=x.character.HumanoidRootPart.Position
-Vector3.new(0,x.character.Humanoid.HipHeight,0),
Size=Vector3.new(al.Value*0.7,0.01,al.Value*0.7),
}
)
:Play()
end
end)
local aQ,aR,aS={},getAttackData()
af=false
F.KillauraTarget=nil
if aR then
local aT=x.AllPosition{
Range=ak.Value,
Wallcheck=ai.Walls.Enabled or nil,
Part="RootPart",
Players=ai.Players.Enabled,
NPCs=ai.NPCs.Enabled,
Limit=ao.Value,
Sort=V[aj.Value],
}

if#aT>0 then
switchItem(aR.tool,0)
local aU=x.character.RootPart.Position
local aV=x.character.RootPart.CFrame.LookVector*Vector3.new(1,0,1)

for aW,aX in aT do
local aY=(aX.RootPart.Position-aU)
local aZ=math.acos(aV:Dot((aY*Vector3.new(1,0,1)).Unit))
if aZ>(math.rad(an.Value)/2)then
continue
end

table.insert(aQ,{
Entity=aX,
Check=aY.Magnitude>al.Value and as or at,
})
A.Targets[aX]=tick()+1

if not af then
af=true
F.KillauraTarget=aX
if not aq.Enabled and aJ<tick()and not aF.Enabled then
aJ=tick()
+(aS.sword.respectAttackSpeedForEffects and aS.sword.attackSpeed or 0)
L.SwordController:playSwordEffect(aS,false)
if aS.displayName:find" Scythe"then
L.ScytheController:playLocalAnimation()
end

if u.ThreadFix then
setthreadidentity(8)
end
end
end

if aY.Magnitude>al.Value then
continue
end

local a_=aX.Character.PrimaryPart
if a_ then
local a0=CFrame.lookAt(aU,a_.Position).LookVector
local a1=aU+a0*math.max(aY.Magnitude-14.399,0)
aO=tick()
L.SwordController.lastAttack=workspace:GetServerTimeNow()
F.attackReach=(aY.Magnitude*100)//1/100
F.attackReachUpdate=tick()+1

if aY.Magnitude<14.4 then
aJ=tick()
end
if tick()>aO then
aO=tick()+(ag.Enabled and 0.22 or 0.1)
aM:FireServer{
weapon=aR.tool,
chargedAttack={chargeRatio=0},
entityInstance=aX.Character,
validate={
raycast={
cameraPosition={value=a1+Vector3.new(0,5,0)},
cursorDirection={value=a0},
},
targetPosition={value=a_.Position},
selfPosition={value=a1},
},
}
aP+=1
end
local a2=getgenv().projectileCount or{}
if#a2>0 then do

aP=0
if ag.Enabled and aE.Enabled then
getgenv().projectileTick=tick()+0.2
task.wait(0.02)
break
end end

end
end
end
end
end

for aT,aU in aH do
aU.Adornee=aQ[aT]and aQ[aT].Entity.RootPart or nil
if aU.Adornee then
aU.Color3=
Color3.fromHSV(aQ[aT].Check.Hue,aQ[aT].Check.Sat,aQ[aT].Check.Value)
aU.Transparency=1-aQ[aT].Check.Opacity
end
end

for aT,aU in aG do
aU.Position=aQ[aT]and aQ[aT].Entity.RootPart.Position or Vector3.new(9e9,9e9,9e9)
aU.Parent=aQ[aT]and r or nil
end

if aA.Enabled and aQ[1]then
local aT=aQ[1].Entity.RootPart.Position*Vector3.new(1,0,1)
x.character.RootPart.CFrame=CFrame.lookAt(
x.character.RootPart.Position,
Vector3.new(aT.X,x.character.RootPart.Position.Y+0.001,aT.Z)
)
end
end,{
name="KillauraFunction",
})
repeat
aQ()

task.wait(1/am.Value)
until not ah.Enabled
else
F.KillauraTarget=nil
for aO,aP in aH do
aP.Adornee=nil
end
for aO,aP in aG do
aP.Parent=nil
end
if k.TouchEnabled then
pcall(function()
s.PlayerGui.MobileUI["2"].Visible=true
end)
end
if az then
pcall(function()
az:Destroy()
end)
az=nil
end
debug.setupvalue(P or L.SwordController.playSwordEffect,6,L.Knit)
debug.setupvalue(L.ScytheController.playLocalAnimation,3,L.Knit)
af=false
if aL then
aK=j:Create(
r.Viewmodel.RightHand.RightWrist,
TweenInfo.new(_.Enabled and 0.001 or 0.3,Enum.EasingStyle.Exponential),
{
C0=aL,
}
)
aK:Play()
end
end
end,
Tooltip="Attack players around you\nwithout aiming at them.",
}
ai=ah:CreateTargets{
Players=true,
NPCs=true,
}
local aN={"Damage","Distance"}
for aO in V do
if not table.find(aN,aO)then
table.insert(aN,aO)
end
end
ak=ah:CreateSlider{
Name="Swing range",
Min=1,
Max=21,
Default=21,
Suffix=function(aO)
return aO==1 and"stud"or"studs"
end,
}
al=ah:CreateSlider{
Name="Attack range",
Min=1,
Max=21,
Default=21,
Suffix=function(aO)
return aO==1 and"stud"or"studs"
end,
}
ay=ah:CreateToggle{
Name="Range Visualiser",
Function=function(aO)
if aO then
createRangeCircle()
else
if az then
az:Destroy()
az=nil
end
end
end,
}
an=ah:CreateSlider{
Name="Max angle",
Min=1,
Max=360,
Default=360,
}
am=ah:CreateSlider{
Name="Update rate",
Min=1,
Max=240,
Default=60,
Suffix="hz",
}
ao=ah:CreateSlider{
Name="Max targets",
Min=1,
Max=5,
Default=5,
}
aj=ah:CreateDropdown{
Name="Target Mode",
List=aN,
}
ap=ah:CreateToggle{Name="Require mouse down"}
aq=ah:CreateToggle{Name="No Swing"}
ar=ah:CreateToggle{Name="GUI check"}
ah:CreateToggle{
Name="Show target",
Function=function(aO)
as.Object.Visible=aO
at.Object.Visible=aO
if aO then
for aP=1,10 do
local aQ=Instance.new"BoxHandleAdornment"
aQ.Adornee=nil
aQ.AlwaysOnTop=true
aQ.Size=Vector3.new(3,5,3)
aQ.CFrame=CFrame.new(0,-0.5,0)
aQ.ZIndex=0
aQ.Parent=u.gui
aH[aP]=aQ
end
else
for aP,aQ in aH do
aQ:Destroy()
end
table.clear(aH)
end
end,
}
as=ah:CreateColorSlider{
Name="Target Color",
Darker=true,
DefaultHue=0.6,
DefaultOpacity=0.5,
Visible=false,
}
at=ah:CreateColorSlider{
Name="Attack Color",
Darker=true,
DefaultOpacity=0.5,
Visible=false,
}
ah:CreateToggle{
Name="Target particles",
Function=function(aO)
au.Object.Visible=aO
av.Object.Visible=aO
aw.Object.Visible=aO
ax.Object.Visible=aO
if aO then
for aP=1,10 do
local aQ=Instance.new"Part"
aQ.Size=Vector3.new(2,4,2)
aQ.Anchored=true
aQ.CanCollide=false
aQ.Transparency=1
aQ.CanQuery=false
aQ.Parent=ah.Enabled and r or nil
local aR=Instance.new"ParticleEmitter"
aR.Brightness=1.5
aR.Size=NumberSequence.new(ax.Value)
aR.Shape=Enum.ParticleEmitterShape.Sphere
aR.Texture=au.Value
aR.Transparency=NumberSequence.new(0)
aR.Lifetime=NumberRange.new(0.4)
aR.Speed=NumberRange.new(16)
aR.Rate=128
aR.Drag=16
aR.ShapePartial=1
aR.Color=ColorSequence.new{
ColorSequenceKeypoint.new(
0,
Color3.fromHSV(av.Hue,av.Sat,av.Value)
),
ColorSequenceKeypoint.new(
1,
Color3.fromHSV(aw.Hue,aw.Sat,aw.Value)
),
}
aR.Parent=aQ
aG[aP]=aQ
end
else
for aP,aQ in aG do
aQ:Destroy()
end
table.clear(aG)
end
end,
}
au=ah:CreateTextBox{
Name="Texture",
Default="rbxassetid://14736249347",
Function=function()
for aO,aP in aG do
aP.ParticleEmitter.Texture=au.Value
end
end,
Darker=true,
Visible=false,
}
av=ah:CreateColorSlider{
Name="Color Begin",
Function=function(aO,aP,aQ)
for aR,aS in aG do
aS.ParticleEmitter.Color=ColorSequence.new{
ColorSequenceKeypoint.new(0,Color3.fromHSV(aO,aP,aQ)),
ColorSequenceKeypoint.new(
1,
Color3.fromHSV(aw.Hue,aw.Sat,aw.Value)
),
}
end
end,
Darker=true,
Visible=false,
}
aw=ah:CreateColorSlider{
Name="Color End",
Function=function(aO,aP,aQ)
for aR,aS in aG do
aS.ParticleEmitter.Color=ColorSequence.new{
ColorSequenceKeypoint.new(
0,
Color3.fromHSV(av.Hue,av.Sat,av.Value)
),
ColorSequenceKeypoint.new(1,Color3.fromHSV(aO,aP,aQ)),
}
end
end,
Darker=true,
Visible=false,
}
ax=ah:CreateSlider{
Name="Size",
Min=0,
Max=1,
Default=0.2,
Decimal=100,
Function=function(aO)
for aP,aQ in aG do
aQ.ParticleEmitter.Size=NumberSequence.new(aO)
end
end,
Darker=true,
Visible=false,
}
aA=ah:CreateToggle{Name="Face target"}
aB=ah:CreateToggle{
Name="Custom Animation",
Function=function(aO)
aC.Object.Visible=aO
_.Object.Visible=aO
Z.Object.Visible=aO
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
local aO={}
for aP in aI do
table.insert(aO,aP)
end
aC=ah:CreateDropdown{
Name="Animation Mode",
List=aO,
Darker=true,
Visible=false,
}
Z=ah:CreateSlider{
Name="Animation Speed",
Min=0,
Max=2,
Default=1,
Decimal=10,
Darker=true,
Visible=false,
}
_=ah:CreateToggle{
Name="No Tween",
Darker=true,
Visible=false,
}
aD=ah:CreateToggle{
Name="Limit to items",
Function=function(aP)
if k.TouchEnabled and ah.Enabled then
pcall(function()
s.PlayerGui.MobileUI["2"].Visible=aP
end)
end
end,
Tooltip="Only attacks when the sword is held",
}
aF=ah:CreateToggle{
Name="Swing only",
Tooltip="Only attacks while swinging manually",
}
end)

b(function()
local ah
local ai
local aj
local ak,al,am=tick(),0
local an={InvokeServer=function()end}
task.spawn(function()
an=L.Client:Get(M.FireProjectile).instance
end)

local function launchProjectile(ao,ap,aq,ar,as)
if not ap then
return
end

ap=ap-as*0.1
local at=(
CFrame.lookAlong(ap,Vector3.new(0,-ar,0))
*CFrame.new(
Vector3.new(
-L.BowConstantsTable.RelX,
-L.BowConstantsTable.RelY,
-L.BowConstantsTable.RelZ
)
)
)
switchItem(ao.tool,0)
L.ProjectileController:createLocalProjectile(
L.ProjectileMeta[aq],
aq,
aq,
at.Position,
"",
at.LookVector*ar,
{drawDurationSeconds=1}
)
if
an:InvokeServer(
ao.tool,
aq,
aq,
at.Position,
ap,
at.LookVector*ar,
i:GenerateGUID(true),
{drawDurationSeconds=1},
workspace:GetServerTimeNow()-0.045
)
then
local au=L.ItemMeta[ao.itemType].projectileSource.launchSound
au=au and au[math.random(1,#au)]or nil
if au then
L.SoundManager:playSound(au)
end
end
end

local ap={
cannon=function(ao,ap,aq)
ap=ap
-Vector3.new(0,(x.character.HipHeight+(x.character.RootPart.Size.Y/2))-3,0)
local ar=Vector3.new(math.round(ap.X/3)*3,math.round(ap.Y/3)*3,math.round(ap.Z/3)*3)
L.placeBlock(ar,"cannon",false)

task.delay(0,function()
local as,at=getPlacedBlock(ar)
if
as
and as.Name=="cannon"
and(x.character.RootPart.Position-as.Position).Magnitude<20
then
local au=L.ItemMeta[as.Name].block.breakType
local av=F.tools[au]
if av then
switchItem(av.tool)
end

L.Client:Get(M.CannonAim):SendToServer{
cannonBlockPos=at,
lookVector=aq,
}

local aw=0.1
if
L.BlockController:calculateBlockDamage(s,{blockPosition=at})
<as:GetAttribute"Health"
then
aw=0.4
L.breakBlock(as,true,true)
end

task.delay(aw,function()
for ax=1,3 do
local ay=
L.Client:Get(M.CannonLaunch):CallServer{cannonBlockPos=at}
if ay then
L.breakBlock(as,true,true)
al=5.25*ah.Value
ak=tick()+2.3
am=Vector3.new(aq.X,0,aq.Z).Unit
break
end
task.wait(0.1)
end
end)
end
end)
end,
cat=function(ao,ap,aq)
ae:Clean(c.CatPounce.Event:Connect(function()
al=4*ah.Value
ak=tick()+2.5
am=Vector3.new(aq.X,0,aq.Z).Unit
x.character.RootPart.Velocity=Vector3.zero
end))

if not L.AbilityController:canUseAbility"CAT_POUNCE"then
repeat
task.wait()
until L.AbilityController:canUseAbility"CAT_POUNCE"or not ae.Enabled
end

if L.AbilityController:canUseAbility"CAT_POUNCE"and ae.Enabled then
L.AbilityController:useAbility"CAT_POUNCE"
end
end,
fireball=function(ap,aq,ar)
launchProjectile(ap,aq,"fireball",60,ar)
end,
grappling_hook=function(ap,aq,ar)
launchProjectile(ap,aq,"grappling_hook_projectile",140,ar)
end,
jade_hammer=function(ap,aq,ar)
if not L.AbilityController:canUseAbility(ap.itemType.."_jump")then
repeat
task.wait()
until L.AbilityController:canUseAbility(ap.itemType.."_jump")or not ae.Enabled
end

if L.AbilityController:canUseAbility(ap.itemType.."_jump")and ae.Enabled then
L.AbilityController:useAbility(ap.itemType.."_jump")
al=1.4*ah.Value
ak=tick()+2.5
am=Vector3.new(ar.X,0,ar.Z).Unit
end
end,
tnt=function(ap,aq,ar)
aq=aq
-Vector3.new(0,(x.character.HipHeight+(x.character.RootPart.Size.Y/2))-3,0)
local as=Vector3.new(math.round(aq.X/3)*3,math.round(aq.Y/3)*3,math.round(aq.Z/3)*3)
aj=Vector3.new(as.X,aj.Y,as.Z)
+(ar*(ap.itemType=="pirate_gunpowder_barrel"and 2.6 or 0.2))
L.placeBlock(as,ap.itemType,false)
end,
wood_dao=function(ap,aq,ar)
if
(s.Character:GetAttribute"CanDashNext"or 0)>workspace:GetServerTimeNow()
or not L.AbilityController:canUseAbility"dash"
then
repeat
task.wait()
until(s.Character:GetAttribute"CanDashNext"or 0)<workspace:GetServerTimeNow()
and L.AbilityController:canUseAbility"dash"
or not ae.Enabled
end

if ae.Enabled then
L.SwordController.lastAttack=workspace:GetServerTimeNow()
switchItem(ap.tool,0.1)
n["events-@easy-games/game-core:shared/game-core-networking@getEvents.Events"].useAbility:FireServer(
"dash",
{
direction=ar,
origin=aq,
weapon=ap.itemType,
}
)
al=4.5*ah.Value
ak=tick()+2.4
am=Vector3.new(ar.X,0,ar.Z).Unit
end
end,
}
for aq,ar in{"stone_dao","iron_dao","diamond_dao","emerald_dao"}do
ap[ar]=ap.wood_dao
end
ap.void_axe=ap.jade_hammer
ap.siege_tnt=ap.tnt
ap.pirate_gunpowder_barrel=ap.tnt

ae=u.Categories.Blatant:CreateModule{
Name="LongJump",
Function=function(aq)
Q.LongJump=aq or nil
updateVelocity()
if aq then
ae:Clean(c.EntityDamageEvent.Event:Connect(function(ar)
if
ar.entityInstance==s.Character
and ar.fromEntity==s.Character
and(not ar.knockbackMultiplier or not ar.knockbackMultiplier.disabled)
then
local as=L.KnockbackUtil.calculateKnockbackVelocity(Vector3.one,1,{
vertical=0,
horizontal=(
ar.knockbackMultiplier and ar.knockbackMultiplier.horizontal or 1
),
}).Magnitude*1.1

if as>=al then
local at=ar.fromPosition
and Vector3.new(
ar.fromPosition.X,
ar.fromPosition.Y,
ar.fromPosition.Z
)
or ar.fromEntity and ar.fromEntity.PrimaryPart.Position
if not at then
return
end
local au=(x.character.RootPart.Position-at)
al=as
ak=tick()+2.5
am=Vector3.new(au.X,0,au.Z).Unit
end
end
end))
ae:Clean(c.GrapplingHookFunctions.Event:Connect(function(ar)
if ar.hookFunction=="PLAYER_IN_TRANSIT"then
local as=x.character.RootPart.CFrame.LookVector
al=2.5*ah.Value
ak=tick()+2.5
am=Vector3.new(as.X,0,as.Z).Unit
end
end))

aj=x.isAlive and x.character.RootPart.Position or nil
ae:Clean(e.PreSimulation:Connect(LPH_NO_VIRTUALIZE(function(ar)
local as=x.isAlive and x.character.RootPart or nil

if as and q(as)then
if ak>tick()then
as.AssemblyLinearVelocity=am
*(getSpeed()+((ak-tick())>1.1 and al or 0))
+Vector3.new(0,as.AssemblyLinearVelocity.Y,0)
if x.character.Humanoid.FloorMaterial==Enum.Material.Air and not aj then
as.AssemblyLinearVelocity+=Vector3.new(0,ar*(workspace.Gravity-23),0)
else
as.AssemblyLinearVelocity=
Vector3.new(as.AssemblyLinearVelocity.X,15,as.AssemblyLinearVelocity.Z)
end
aj=nil
else
if aj then
as.CFrame=CFrame.lookAlong(aj,as.CFrame.LookVector)
end
as.AssemblyLinearVelocity=Vector3.zero
al=0
end
else
aj=nil
end
end)))

if F.hand and ap[F.hand.tool.Name]then
task.spawn(
ap[F.hand.tool.Name],
getItem(F.hand.tool.Name),
aj,
(ai.Enabled and r or x.character.RootPart).CFrame.LookVector
)
return
end

for ar,as in ap do
local at=getItem(ar)
if at or L.isKitEquipped(ar)then
task.spawn(
as,
at,
aj,
(ai.Enabled and r or x.character.RootPart).CFrame.LookVector
)
break
end
end
else
ak=tick()
am=nil
al=0
end
end,
ExtraText=function()
return"Heatseeker"
end,
Tooltip="Lets you jump farther",
}
ah=ae:CreateSlider{
Name="Speed",
Min=1,
Max=37,
Default=37,
Suffix=function(aq)
return aq==1 and"stud"or"studs"
end,
}
ai=ae:CreateToggle{
Name="Camera Direction",
}
end)

b(function()
local ah
local ai
local aj=RaycastParams.new()
local ak
task.spawn(function()
ak=L.Client:Get(M.GroundHit).instance
end)

ah=u.Categories.Blatant:CreateModule{
Name="NoFall",
Function=function(al)
if al then
local am=0
ai.Value="Packet"
if ai.Value=="Gravity"then
local an=0
ah:Clean(e.PreSimulation:Connect(LPH_NO_VIRTUALIZE(function(ap)
if x.isAlive then
local aq=x.character.RootPart
if aq.AssemblyLinearVelocity.Y<-85 then
aj.FilterDescendantsInstances={s.Character,r}
aj.CollisionGroup=aq.CollisionGroup

local ar=aq.Size.Y/2+x.character.HipHeight
local as=workspace:Blockcast(
aq.CFrame,
Vector3.new(3,3,3),
Vector3.new(0,(am*0.1)-ar,0),
aj
)
if not as then
aq.AssemblyLinearVelocity=
Vector3.new(aq.AssemblyLinearVelocity.X,-86,aq.AssemblyLinearVelocity.Z)
aq.CFrame+=Vector3.new(0,an*ap,0)
an+=-workspace.Gravity*ap
end
else
an=0
end
end
end)))
else
repeat
if x.isAlive then
local an=x.character.RootPart
am=x.character.Humanoid.FloorMaterial==Enum.Material.Air
and math.min(am,an.AssemblyLinearVelocity.Y)
or 0

if am<-85 then
pcall(function()
x.character.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
end)
if ai.Value=="Packet"then
ak:FireServer(workspace,Vector3.new(0,am,0),workspace:GetServerTimeNow()+0.35)
else
aj.FilterDescendantsInstances={s.Character,r}
aj.CollisionGroup=an.CollisionGroup

local ap=an.Size.Y/2+x.character.HipHeight
if ai.Value=="Teleport"then
local aq=workspace:Blockcast(
an.CFrame,
Vector3.new(3,3,3),
Vector3.new(0,-1E3,0),
aj
)
if aq then
an.CFrame-=Vector3.new(
0,
an.Position.Y-(aq.Position.Y+ap),
0
)
end
else
local aq=workspace:Blockcast(
an.CFrame,
Vector3.new(3,3,3),
Vector3.new(0,(am*0.1)-ap,0),
aj
)
if aq then
am=0
an.AssemblyLinearVelocity=Vector3.new(
an.AssemblyLinearVelocity.X,-80
,
an.AssemblyLinearVelocity.Z
)
end
end
end
end
end

task.wait(0.03)
until not ah.Enabled
end
end
end,
Tooltip="Prevents taking fall damage.",
}
ai=ah:CreateDropdown{
Name="Mode",
List={"Packet"},
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
end)

b(function()
local ah

u.Categories.Blatant:CreateModule{
Name="NoSlowdown",
Function=function(ai)
local aj=L.SprintController:getMovementStatusModifier()
if ai then
ah=aj.addModifier
aj.addModifier=function(ak,al)
if al.moveSpeedMultiplier then
al.moveSpeedMultiplier=math.max(al.moveSpeedMultiplier,1)
end
return ah(ak,al)
end

for ak in aj.modifiers do
if(ak.moveSpeedMultiplier or 1)<1 then
aj:removeModifier(ak)
end
end
else
aj.addModifier=ah
ah=nil
end
end,
Tooltip="Prevents slowing down when using items.",
}
end)

b(function()
local ah
local ai
local aj
local ak
local al
local am=RaycastParams.new()
am.FilterType=Enum.RaycastFilterType.Include
am.FilterDescendantsInstances={workspace:FindFirstChild"Map"}
local an

local ap=u.Categories.Blatant:CreateModule{
Name="ProjectileAimbot",
Function=function(ap)
if ap then
an=L.ProjectileController.calculateImportantLaunchValues
L.ProjectileController.calculateImportantLaunchValues=function(...)
local aq,ar,as,at,au=...
local av=x.EntityMouse{
Part="RootPart",
Range=aj.Value,
Players=ai.Players.Enabled,
NPCs=ai.NPCs.Enabled,
Wallcheck=ai.Walls.Enabled,
Origin=x.isAlive and(au or x.character.RootPart.Position)
or Vector3.zero,
}

if av then
local aw=au or aq:getLaunchPosition(at)
if not aw then
return an(...)
end

if(not ak.Enabled)and not ar.projectile:find"arrow"then
return an(...)
end

local ax=ar:getProjectileMeta()
local ay=(as and ax.predictionLifetimeSec or ax.lifetimeSec or 3)
local az=(ax.gravitationalAcceleration or 196.2)*ar.gravityMultiplier
local aA=(ax.launchVelocity or 100)
local aB=aw
+(ar.projectile=="owl_projectile"and Vector3.zero or ar.fromPositionOffset)
local aC=av.Character:GetAttribute"InflatedBalloons"
local aD=workspace.Gravity

if aC and aC>0 then
aD=(
workspace.Gravity*(1-(aC>=4 and 1.2 or aC>=3 and 1 or 0.975))
)
end

if av.Character.PrimaryPart:FindFirstChild"rbxassetid://8200754399"then
aD=6
end

if av.Player then
if av.Player:GetAttribute"IsOwlTarget"then
for aE,aF in o:GetTagged"Owl"do
if
aF:GetAttribute"Target"==av.Player.UserId
and aF:GetAttribute"Status"==2
then
aD=0
end
end
end
end

if math.random(1,100)>al.Value then
local aE=Vector3.new(
(math.random()-0.5)*20,
(math.random()-0.5)*20,
(math.random()-0.5)*20
)
local aF=CFrame.new(aB,av[ah.Value].Position+aE)
*CFrame.new(
ar.projectile=="owl_projectile"and Vector3.zero
or Vector3.new(
L.BowConstantsTable.RelX,
L.BowConstantsTable.RelY,
L.BowConstantsTable.RelZ
)
)
local aG=B.SolveTrajectory(
aF.p,
aA,
az,
av[ah.Value].Position+aE,
ar.projectile=="telepearl"and Vector3.zero or av[ah.Value].Velocity,
aD,
av.HipHeight,
av.Jumping and 42.6 or nil,
am
)
if aG then
return{
initialVelocity=CFrame.new(aF.Position,aG).LookVector*aA,
positionFrom=aB,
deltaT=ay,
gravitationalAcceleration=az,
drawDurationSeconds=5,
}
end
else
local aE=CFrame.new(aB,av[ah.Value].Position)
*CFrame.new(
ar.projectile=="owl_projectile"and Vector3.zero
or Vector3.new(
L.BowConstantsTable.RelX,
L.BowConstantsTable.RelY,
L.BowConstantsTable.RelZ
)
)
local aF=B.SolveTrajectory(
aE.p,
aA,
az,
av[ah.Value].Position,
ar.projectile=="telepearl"and Vector3.zero or av[ah.Value].Velocity,
aD,
av.HipHeight,
av.Jumping and 42.6 or nil,
am
)
if aF then
A.Targets[av]=tick()+1
return{
initialVelocity=CFrame.new(aE.Position,aF).LookVector*aA,
positionFrom=aB,
deltaT=ay,
gravitationalAcceleration=az,
drawDurationSeconds=5,
}
end
end
end

return an(...)
end
else
L.ProjectileController.calculateImportantLaunchValues=an
end
end,
Tooltip="Silently adjusts your aim towards the enemy",
}
ai=ap:CreateTargets{
Players=true,
Walls=true,
}
ah=ap:CreateDropdown{
Name="Part",
List={"RootPart","Head"},
}
aj=ap:CreateSlider{
Name="FOV",
Min=1,
Max=1000,
Default=1000,
}
ak=ap:CreateToggle{
Name="Other Projectiles",
Default=true,
}
al=ap:CreateSlider{
Name="Hit Chance",
Min=0,
Max=100,
Default=100,
Suffix="%",
}
end)

b(function()
local ah
local ai
local aj
local ak=RaycastParams.new()
ak.FilterType=Enum.RaycastFilterType.Include
local al={InvokeServer=function()end}
local am={}
task.spawn(function()
al=L.Client:Get(M.FireProjectile).instance
end)

local function getAmmo(an)
for ap,aq in F.inventory.inventory.items do
if an.ammoItemTypes and table.find(an.ammoItemTypes,aq.itemType)then
return aq.itemType
end
end
end

local function getProjectiles()
local an={}
for ap,aq in F.inventory.inventory.items do
local ar=L.ItemMeta[aq.itemType]and L.ItemMeta[aq.itemType].projectileSource
if not ar then
continue
end
local as=ar and getAmmo(ar)
if not ar.projectileType then

continue
end
if as and table.find(aj.ListEnabled,as)then
table.insert(an,{
aq,
as,
ar.projectileType(as),
ar,
})
end
end
return an
end
local function fireRaven(an,ap)
if not ap then
return
end
if not an then
return
end
if not an.tool then
return
end
pcall(switchItem,an.tool)
L.Client:Get(M.SpawnRaven):CallServerAsync():andThen(function(aq)
if aq then
local ar=Instance.new"BodyForce"
ar.Force=Vector3.new(0,aq.PrimaryPart.AssemblyMass*workspace.Gravity,0)
ar.Parent=aq.PrimaryPart

if ap then
task.spawn(function()
for as=1,20 do
if ap and aq then
aq:SetPrimaryPartCFrame(
CFrame.lookAlong(ap.Position,r.CFrame.LookVector)
)
end
task.wait(0.05)
end
end)
task.wait(0.3)
L.RavenController:detonateRaven()
end
end
end)
end
local an
getgenv().projectileTick=tick()
getgenv().projectileCount={}
ag=u.Categories.Blatant:CreateModule{
Name="ProjectileAura",
Function=function(ap)
if ap then
repeat
if F.matchState==0 then
task.wait(1)
return
end
if
(workspace:GetServerTimeNow()-L.SwordController.lastAttack)>0.5
or getgenv().projectileTick>=tick()
then
local aq=x.EntityPosition{
Part="RootPart",
Range=ai.Value,
Players=ah.Players.Enabled,
NPCs=ah.NPCs.Enabled,
Wallcheck=ah.Walls.Enabled,
}

if aq then
local ar=x.character.RootPart.Position
if an.Enabled then
local as=getItem"raven"
if as then
local at,au=pcall(fireRaven,as,aq.RootPart)
if not at then
errorNotification("ProjectileAura - Raven Aura",tostring(au),5)
end
end
end
local as=getProjectiles()
getgenv().projectileCount=as
for at,au in as do
local av,aw,ax,ay=unpack(au)
if(am[av.itemType]or 0)<tick()then
ak.FilterDescendantsInstances={workspace.Map}
local az=L.ProjectileMeta[ax]
local aA,aB=
az.launchVelocity,az.gravitationalAcceleration or 196.2
local aC=B.SolveTrajectory(
ar,
aA,
aB,
aq.RootPart.Position,
aq.RootPart.Velocity,
workspace.Gravity,
aq.HipHeight,
aq.Jumping and 42.6 or nil,
ak
)
if aC then
A.Targets[aq]=tick()+1
local aD=switchItem(av.tool)

task.spawn(function()
local aE,aF=
CFrame.lookAt(ar,aC).LookVector,i:GenerateGUID(true)
local aG=(CFrame.new(ar,aC)*CFrame.new(
Vector3.new(
-L.BowConstantsTable.RelX,
-L.BowConstantsTable.RelY,
-L.BowConstantsTable.RelZ
)
)).Position
local aH=al:InvokeServer(
av.tool,
aw,
ax,
aG,
ar,
aE*aA,
aF,
{drawDurationSeconds=1,shotId=i:GenerateGUID(false)},
workspace:GetServerTimeNow()-0.045
)
if not aH then
am[av.itemType]=tick()
else
local aI=ay.launchSound
aI=aI and aI[math.random(1,#aI)]or nil
if aI then
L.SoundManager:playSound(aI)
end
end
end)

am[av.itemType]=tick()+ay.fireDelaySec
if aD then
task.wait(0.05)
end
end
end
end
end
end
task.wait(0.1)
until not ag.Enabled
end
end,
Tooltip="Shoots people around you",
}
ah=ag:CreateTargets{
Players=true,
Walls=true,
}
aj=ag:CreateTextList{
Name="Projectiles",
Default={"arrow","snowball"},
}
ai=ag:CreateSlider{
Name="Range",
Min=1,
Max=50,
Default=50,
Suffix=function(ap)
return ap==1 and"stud"or"studs"
end,
}
an=ag:CreateToggle{
Name="Raven Aura",
Function=function()end,
Default=false,
}
end)

b(function()
local ah
local ai
local aj
local ak
local al
local am=RaycastParams.new()
am.RespectCanCollide=true

ah=u.Categories.Blatant:CreateModule{
Name="Speed",
Function=function(an)
Q.Speed=an or nil
updateVelocity()
pcall(function()
debug.setconstant(
L.WindWalkerController.updateSpeed,
7,
an and"constantSpeedMultiplier"or"moveSpeedMultiplier"
)
end)

if an then
ah:Clean(e.PreSimulation:Connect(LPH_NO_VIRTUALIZE(function(ap)
L.StatefulEntityKnockbackController.lastImpulseTime=an and math.huge or time()
if
x.isAlive
and not ad.Enabled
and not I.Enabled
and not ae.Enabled
and q(x.character.RootPart)
then
local aq=x.character.Humanoid:GetState()
if aq==Enum.HumanoidStateType.Climbing then
return
end

local ar,as=x.character.RootPart,getSpeed()
local at=ac or x.character.Humanoid.MoveDirection
local au=(at*math.max(ai.Value-as,0)*ap)

if aj.Enabled then
am.FilterDescendantsInstances={s.Character,r}
am.CollisionGroup=ar.CollisionGroup
local av=blocksRaycast(au)

if av then
au=((av.Position+av.Normal)-ar.Position)
end
end

ar.CFrame+=au
ar.AssemblyLinearVelocity=(at*as)
+Vector3.new(0,ar.AssemblyLinearVelocity.Y,0)
if
ak.Enabled
and(aq==Enum.HumanoidStateType.Running or aq==Enum.HumanoidStateType.Landed)
and at~=Vector3.zero
and(af or al.Enabled)
then
x.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end
end
end)))
end
end,
ExtraText=function()
return"Heatseeker"
end,
Tooltip="Increases your movement with various methods.",
}
ai=ah:CreateSlider{
Name="Speed",
Min=1,
Max=23,
Default=23,
Suffix=function(an)
return an==1 and"stud"or"studs"
end,
}
aj=ah:CreateToggle{
Name="Wall Check",
Default=true,
}
ak=ah:CreateToggle{
Name="AutoJump",
Function=function(an)
al.Object.Visible=an
end,
}
al=ah:CreateToggle{
Name="Always Jump",
Visible=false,
Darker=true,
}
end)

b(function()
local ah
local ai={}
local aj=Instance.new"Folder"
aj.Parent=u.gui

local function Added(ak)
if not ah.Enabled then
return
end
local al=Instance.new"Folder"
al.Parent=aj
ai[ak]=al
local am=ak:GetChildren()
table.sort(am,function(an,ap)
return an.Name>ap.Name
end)

for an,ap in am do
if ap:IsA"BasePart"and ap.Name~="Blanket"then
local aq=Instance.new"BoxHandleAdornment"
aq.Size=ap.Size+Vector3.new(0.01,0.01,0.01)
aq.AlwaysOnTop=true
aq.ZIndex=2
aq.Visible=true
aq.Adornee=ap
aq.Color3=ap.Color
if ap.Name=="Legs"then
aq.Color3=Color3.fromRGB(167,112,64)
aq.Size=ap.Size+Vector3.new(0.01,-1,0.01)
aq.CFrame=CFrame.new(0,-0.4,0)
aq.ZIndex=0
end
aq.Parent=al
end
end

table.clear(am)
end

ah=u.Categories.Render:CreateModule{
Name="BedESP",
Function=function(ak)
if ak then
ah:Clean(o:GetInstanceAddedSignal"bed":Connect(function(al)
task.delay(0.2,Added,al)
end))
ah:Clean(o:GetInstanceRemovedSignal"bed":Connect(function(al)
if ai[al]then
ai[al]:Destroy()
ai[al]=nil
end
end))
for al,am in o:GetTagged"bed"do
Added(am)
end
else
aj:ClearAllChildren()
table.clear(ai)
end
end,
Tooltip="Render Beds through walls",
}
end)

b(function()
local ah

ah=u.Categories.Render:CreateModule{
Name="Health",
Function=function(ai)
if ai then
local aj=Instance.new"TextLabel"
aj.Size=UDim2.fromOffset(100,20)
aj.Position=UDim2.new(0.5,6,0.5,30)
aj.BackgroundTransparency=1
aj.AnchorPoint=Vector2.new(0.5,0)
aj.Text=x.isAlive and math.round(s.Character:GetAttribute"Health").." ❤️"or""
aj.TextColor3=x.isAlive
and Color3.fromHSV(
(s.Character:GetAttribute"Health"/s.Character:GetAttribute"MaxHealth")/2.8,
0.86,
1
)
or Color3.new()
aj.TextSize=18
aj.Font=Enum.Font.Arial
aj.Parent=u.gui
ah:Clean(aj)
ah:Clean(c.AttributeChanged.Event:Connect(function()
aj.Text=x.isAlive and math.round(s.Character:GetAttribute"Health").." ❤️"
or""
aj.TextColor3=x.isAlive
and Color3.fromHSV(
(s.Character:GetAttribute"Health"/s.Character:GetAttribute"MaxHealth")/2.8,
0.86,
1
)
or Color3.new()
end))
end
end,
Tooltip="Displays your health in the center of your screen.",
}
end)

b(function()
local ah
local ai
local aj={}
local ak={}
local al=Instance.new"Folder"
al.Parent=u.gui

local am={
alchemist={"alchemist_ingedients","wild_flower"},
beekeeper={"bee","bee"},
bigman={"treeOrb","natures_essence_1"},
ghost_catcher={"ghost","ghost_orb"},
metal_detector={"hidden-metal","iron"},
sheep_herder={"SheepModel","purple_hay_bale"},
sorcerer={"alchemy_crystal","wild_flower"},
star_collector={"stars","crit_star"},
}

local function Added(an,ap)
local aq=Instance.new"BillboardGui"
aq.Parent=al
aq.Name=ap
aq.StudsOffsetWorldSpace=Vector3.new(0,3,0)
aq.Size=UDim2.fromOffset(36,36)
aq.AlwaysOnTop=true
aq.ClipsDescendants=false
aq.Adornee=an
local ar=addBlur(aq)
ar.Visible=ai.Enabled
local as=Instance.new"ImageLabel"
as.Size=UDim2.fromOffset(36,36)
as.Position=UDim2.fromScale(0.5,0.5)
as.AnchorPoint=Vector2.new(0.5,0.5)
as.BackgroundColor3=Color3.fromHSV(aj.Hue,aj.Sat,aj.Value)
as.BackgroundTransparency=1-(ai.Enabled and aj.Opacity or 0)
as.BorderSizePixel=0
as.Image=L.getIcon({itemType=ap},true)
as.Parent=aq
local at=Instance.new"UICorner"
at.CornerRadius=UDim.new(0,4)
at.Parent=as
ak[an]=aq
end

local function addKit(an,ap)
ah:Clean(o:GetInstanceAddedSignal(an):Connect(function(aq)
Added(aq.PrimaryPart,ap)
end))
ah:Clean(o:GetInstanceRemovedSignal(an):Connect(function(aq)
if ak[aq.PrimaryPart]then
ak[aq.PrimaryPart]:Destroy()
ak[aq.PrimaryPart]=nil
end
end))
for aq,ar in o:GetTagged(an)do
Added(ar.PrimaryPart,ap)
end
end

local an
ah=u.Categories.Render:CreateModule{
Name="KitESP",
Function=function(ap)
if ap then
repeat
task.wait()
until F.equippedKit~=""or not ah.Enabled
an=true
for aq,ar in am do
local as=ah.Enabled and L.isKitEquipped(aq)and am[aq]or nil
if as then
addKit(as[1],as[2])
end
end
else
al:ClearAllChildren()
table.clear(ak)
end
end,
Tooltip="ESP for certain kit related objects",
}
c.EquippedKitChanged:Connect(function()
if ah.Enabled and an then
ah:Toggle()
task.wait(0.1)
ah:Toggle()
end
end)
ai=ah:CreateToggle{
Name="Background",
Function=function(ap)
if aj.Object then
aj.Object.Visible=ap
end
for aq,ar in ak do
ar.ImageLabel.BackgroundTransparency=1-(ap and aj.Opacity or 0)
ar.Blur.Visible=ap
end
end,
Default=true,
}
aj=ah:CreateColorSlider{
Name="Background Color",
DefaultValue=0,
DefaultOpacity=0.5,
Function=function(ap,aq,ar,as)
for at,au in ak do
au.ImageLabel.BackgroundColor3=Color3.fromHSV(ap,aq,ar)
au.ImageLabel.BackgroundTransparency=1-as
end
end,
Darker=true,
}
end)

b(function()
local ah
local ai
local aj
local ak
local al
local am
local an
local ap
local aq
local ar
local as
local at
local au
local av
local aw
local ax,ay,az={},{},{}
local aA=Instance.new"Folder"
aA.Parent=u.gui
local aB

local aC={
Normal=function(aC)
if not ai.Players.Enabled and aC.Player then
return
end
if not ai.NPCs.Enabled and aC.NPC then
return
end
if au.Enabled and not aC.Targetable and not aC.Friend then
return
end

local aD=Instance.new"TextLabel"
ax[aC]=aC.Player
and z:tag(aC.Player,true,true)..(al.Enabled and aC.Player.DisplayName or aC.Player.Name)
or aC.Character.Name

if am.Enabled then
local aE=Color3.fromHSV(math.clamp(aC.Health/aC.MaxHealth,0,1)/2.5,0.89,0.75)
ax[aC]=ax[aC]
..' <font color="rgb('
..tostring(math.floor(aE.R*255))
..","
..tostring(math.floor(aE.G*255))
..","
..tostring(math.floor(aE.B*255))
..')">'
..math.round(aC.Health)
.."</font>"
end

if an.Enabled then
ax[aC]='<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '
..ax[aC]
end























local aE=30
local aF=2

local aG=ap.Enabled and 0 or 0
local aH=(aq.Enabled and aC.Player)and 1 or 0
local aI=aG+aH

local aJ=(aI*aE)+((aI-1)*aF)
local aK=-(aJ/2)

if aq.Enabled and aC.Player then
local aL=Instance.new"ImageLabel"
aL.Name="Enchant"
aL.Size=UDim2.fromOffset(aE,aE)
aL.Position=UDim2.fromOffset(aK,-30)
aL.BackgroundTransparency=1
aL.Image=""
aL.Parent=aD

aK=aK+aE+aF
end

if ap.Enabled then
for aL,aM in{"Hand","Helmet","Chestplate","Boots","Kit"}do
local aN=Instance.new"ImageLabel"
aN.Name=aM
aN.Size=UDim2.fromOffset(aE,aE)
aN.Position=UDim2.fromOffset(aK+((aL-1)*(aE+aF)),-30)
aN.BackgroundTransparency=1
aN.Image=""
aN.Parent=aD
end
end

aD.TextSize=14*as.Value
aD.FontFace=at.Value
local aL=
D(removeTags(ax[aC]),aD.TextSize,aD.FontFace,Vector2.new(100000,100000))
aD.Name=aC.Player and aC.Player.Name or aC.Character.Name
aD.Size=UDim2.fromOffset(aL.X+8,aL.Y+7)
aD.AnchorPoint=Vector2.new(0.5,1)
aD.BackgroundColor3=Color3.new()
aD.BackgroundTransparency=ak.Value
aD.BorderSizePixel=0
aD.Visible=false
aD.Text=ax[aC]
aD.TextColor3=x.getEntityColor(aC)or Color3.fromHSV(aj.Hue,aj.Sat,aj.Value)
aD.RichText=true
aD.Parent=aA
az[aC]=aD
end,
Drawing=function(aC)
if not ai.Players.Enabled and aC.Player then
return
end
if not ai.NPCs.Enabled and aC.NPC then
return
end
if au.Enabled and not aC.Targetable and not aC.Friend then
return
end

local aD={}
aD.BG=Drawing.new"Square"
aD.BG.Filled=true
aD.BG.Transparency=1-ak.Value
aD.BG.Color=Color3.new()
aD.BG.ZIndex=1
aD.Text=Drawing.new"Text"
aD.Text.Size=15*as.Value
aD.Text.Font=0
aD.Text.ZIndex=2
ax[aC]=aC.Player
and z:tag(aC.Player,true)..(al.Enabled and aC.Player.DisplayName or aC.Player.Name)
or aC.Character.Name

if am.Enabled then
ax[aC]=ax[aC].." "..math.round(aC.Health)
end

if an.Enabled then
ax[aC]="[%s] "..ax[aC]
end

aD.Text.Text=ax[aC]
aD.Text.Color=x.getEntityColor(aC)or Color3.fromHSV(aj.Hue,aj.Sat,aj.Value)
aD.BG.Size=Vector2.new(aD.Text.TextBounds.X+8,aD.Text.TextBounds.Y+7)
az[aC]=aD
end,
}

local aD={
Normal=function(aD)
local aE=az[aD]
if aE then
az[aD]=nil
ax[aD]=nil
ay[aD]=nil
aE:Destroy()
end
end,
Drawing=function(aD)
local aE=az[aD]
if aE then
az[aD]=nil
ax[aD]=nil
ay[aD]=nil
for aF,aG in aE do
pcall(function()
aG.Visible=false
aG:Remove()
end)
end
end
end,
}

local aE={
Normal=function(aE)
local aF=az[aE]
if aF then
ay[aE]=nil
ax[aE]=aE.Player
and z:tag(aE.Player,true,true)..(al.Enabled and aE.Player.DisplayName or aE.Player.Name)
or aE.Character.Name

if am.Enabled then
local aG=Color3.fromHSV(math.clamp(aE.Health/aE.MaxHealth,0,1)/2.5,0.89,0.75)
ax[aE]=ax[aE]
..' <font color="rgb('
..tostring(math.floor(aG.R*255))
..","
..tostring(math.floor(aG.G*255))
..","
..tostring(math.floor(aG.B*255))
..')">'
..math.round(aE.Health)
.."</font>"
end

if an.Enabled then
ax[aE]='<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '
..ax[aE]
end

if ap.Enabled and F.inventories[aE.Player]then
local aG=aE.Player:GetAttribute"PlayingAsKits"
local aH=F.inventories[aE.Player]
aF.Hand.Image=L.getIcon(aH.hand or{itemType=""},true)
aF.Helmet.Image=L.getIcon(aH.armor[1]or{itemType=""},true)
aF.Chestplate.Image=L.getIcon(aH.armor[2]or{itemType=""},true)
aF.Boots.Image=L.getIcon(aH.armor[3]or{itemType=""},true)
aF.Kit.Image=aG
and aG~="none"
and L.BedwarsKitMeta[aG]
and L.BedwarsKitMeta[aG]
and L.BedwarsKitMeta[aG].renderImage
or""
end

if aq.Enabled and aE.Player and aF:FindFirstChild"Enchant"then
local aG=L.EnchantTableController.enchants[aE.Player.UserId]
if aG~=nil and aG.image then
aF.Enchant.Image=aG.image
else
aF.Enchant.Image=""
end
end

local aG=D(
removeTags(ax[aE]),
aF.TextSize,
aF.FontFace,
Vector2.new(100000,100000)
)
aF.Size=UDim2.fromOffset(aG.X+8,aG.Y+7)
aF.Text=ax[aE]
end
end,
Drawing=function(aE)
local aF=az[aE]
if aF then
if u.ThreadFix then
setthreadidentity(8)
end
ay[aE]=nil
ax[aE]=aE.Player
and z:tag(aE.Player,true)..(al.Enabled and aE.Player.DisplayName or aE.Player.Name)
or aE.Character.Name

if am.Enabled then
ax[aE]=ax[aE].." "..math.round(aE.Health)
end

if an.Enabled then
ax[aE]="[%s] "..ax[aE]
aF.Text.Text=x.isAlive
and string.format(
ax[aE],
math.floor((x.character.RootPart.Position-aE.RootPart.Position).Magnitude)
)
or ax[aE]
else
aF.Text.Text=ax[aE]
end

aF.BG.Size=Vector2.new(aF.Text.TextBounds.X+8,aF.Text.TextBounds.Y+7)
aF.Text.Color=x.getEntityColor(aE)or Color3.fromHSV(aj.Hue,aj.Sat,aj.Value)
end
end,
}

local aF={
Normal=function(aF,aG,aH)
local aI=Color3.fromHSV(aF,aG,aH)
for aJ,aK in az do
aK.TextColor3=x.getEntityColor(aJ)or aI
end
end,
Drawing=function(aF,aG,aH)
local aI=Color3.fromHSV(aF,aG,aH)
for aJ,aK in az do
aK.Text.Color=x.getEntityColor(aJ)or aI
end
end,
}

local aG={
Normal=function()
for aG,aH in az do
if av.Enabled then
local aI=x.isAlive
and(x.character.RootPart.Position-aG.RootPart.Position).Magnitude
or math.huge
if aI<aw.ValueMin or aI>aw.ValueMax then
aH.Visible=false
continue
end
end

local aI,aJ=
r:WorldToViewportPoint(aG.RootPart.Position+Vector3.new(0,aG.HipHeight+1,0))
aH.Visible=aJ
if not aJ then
continue
end

if an.Enabled then
local aK=x.isAlive
and math.floor((x.character.RootPart.Position-aG.RootPart.Position).Magnitude)
or 0
if ay[aG]~=aK then
aH.Text=string.format(ax[aG],aK)
local aL=D(
removeTags(aH.Text),
aH.TextSize,
aH.FontFace,
Vector2.new(100000,100000)
)
aH.Size=UDim2.fromOffset(aL.X+8,aL.Y+7)
ay[aG]=aK
end
end
aH.Position=UDim2.fromOffset(aI.X,aI.Y)

if ap.Enabled and F.inventories[aG.Player]then
local aK=aG.Player:GetAttribute"PlayingAsKits"
local aL=F.inventories[aG.Player]
aH.Hand.Image=L.getIcon(aL.hand or{itemType=""},true)
aH.Helmet.Image=L.getIcon(aL.armor[1]or{itemType=""},true)
aH.Chestplate.Image=L.getIcon(aL.armor[2]or{itemType=""},true)
aH.Boots.Image=L.getIcon(aL.armor[3]or{itemType=""},true)
aH.Kit.Image=aK
and aK~="none"
and L.BedwarsKitMeta[aK]
and L.BedwarsKitMeta[aK].renderImage
or""
end
end
end,
Drawing=function()
for aG,aH in az do
if av.Enabled then
local aI=x.isAlive
and(x.character.RootPart.Position-aG.RootPart.Position).Magnitude
or math.huge
if aI<aw.ValueMin or aI>aw.ValueMax then
aH.Text.Visible=false
aH.BG.Visible=false
continue
end
end

local aI,aJ=
r:WorldToViewportPoint(aG.RootPart.Position+Vector3.new(0,aG.HipHeight+1,0))
aH.Text.Visible=aJ
aH.BG.Visible=aJ
if not aJ then
continue
end

if an.Enabled then
local aK=x.isAlive
and math.floor((x.character.RootPart.Position-aG.RootPart.Position).Magnitude)
or 0
if ay[aG]~=aK then
aH.Text.Text=string.format(ax[aG],aK)
aH.BG.Size=Vector2.new(aH.Text.TextBounds.X+8,aH.Text.TextBounds.Y+7)
ay[aG]=aK
end
end
aH.BG.Position=Vector2.new(aI.X-(aH.BG.Size.X/2),aI.Y-aH.BG.Size.Y)
aH.Text.Position=aH.BG.Position+Vector2.new(4,3)
end
end,
}

ah=u.Categories.Render:CreateModule{
Name="NameTags",
Function=function(aH)
if aH then
aB=ar.Enabled and"Drawing"or"Normal"
if aD[aB]then
ah:Clean(x.Events.EntityRemoved:Connect(aD[aB]))
end
if aC[aB]then
for aI,aJ in x.List do
if az[aJ]then
aD[aB](aJ)
end
aC[aB](aJ)
end
ah:Clean(x.Events.EntityAdded:Connect(function(aI)
if az[aI]then
aD[aB](aI)
end
aC[aB](aI)
end))
end
if aE[aB]then
ah:Clean(x.Events.EntityUpdated:Connect(aE[aB]))
for aI,aJ in x.List do
aE[aB](aJ)
end
end
if aF[aB]then
ah:Clean(u.Categories.Friends.ColorUpdate.Event:Connect(function()
aF[aB](aj.Hue,aj.Sat,aj.Value)
end))
end
if aG[aB]then
ah:Clean(e.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
aG[aB]()
end)))
end
else
if aD[aB]then
for aI in az do
aD[aB](aI)
end
end
end
end,
Tooltip="Renders nametags on entities through walls.",
}
ai=ah:CreateTargets{
Players=true,
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
at=ah:CreateFont{
Name="Font",
Blacklist="Arial",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
aj=ah:CreateColorSlider{
Name="Player Color",
Function=function(aH,aI,aJ)
if ah.Enabled and aF[aB]then
aF[aB](aH,aI,aJ)
end
end,
}
as=ah:CreateSlider{
Name="Scale",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
Default=1,
Min=0.1,
Max=1.5,
Decimal=10,
}
ak=ah:CreateSlider{
Name="Transparency",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
Default=0.5,
Min=0,
Max=1,
Decimal=10,
}
am=ah:CreateToggle{
Name="Health",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
an=ah:CreateToggle{
Name="Distance",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
ap=ah:CreateToggle{
Name="Equipment",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
aq=ah:CreateToggle{
Name="Enchant",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
al=ah:CreateToggle{
Name="Use Displayname",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
Default=true,
}
au=ah:CreateToggle{
Name="Priority Only",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
Default=true,
}
ar=ah:CreateToggle{
Name="Drawing",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
av=ah:CreateToggle{
Name="Distance Check",
Function=function(aH)
aw.Object.Visible=aH
end,
}
aw=ah:CreateTwoSlider{
Name="Player Distance",
Min=0,
Max=256,
DefaultMin=0,
DefaultMax=64,
Darker=true,
Visible=false,
}
end)

b(function()
local ah
local ai
local aj
local ak={}
local al={}
local am=Instance.new"Folder"
am.Parent=u.gui

local function nearStorageItem(an)
for ap,aq in ai.ListEnabled do
if an:find(aq)then
return aq
end
end
end

local function refreshAdornee(an)
local ap=an.Adornee:FindFirstChild"ChestFolderValue"
ap=ap and ap.Value or nil
if not ap then
an.Enabled=false
return
end

local aq=ap and ap:GetChildren()or{}
for ar,as in an.Frame:GetChildren()do
if as:IsA"ImageLabel"and as.Name~="Blur"then
as:Destroy()
end
end

an.Enabled=false
local ar={}
for as,at in aq do
if
not ar[at.Name]and(table.find(ai.ListEnabled,at.Name)or nearStorageItem(at.Name))
then
ar[at.Name]=true
an.Enabled=true
local au=Instance.new"ImageLabel"
au.Size=UDim2.fromOffset(32,32)
au.BackgroundTransparency=1
au.Image=L.getIcon({itemType=at.Name},true)
au.Parent=an.Frame
end
end
table.clear(aq)
end

local function Added(an)
local ap=an:WaitForChild("ChestFolderValue",3)
if not(ap and ah.Enabled)then
return
end
ap=ap.Value
local aq=Instance.new"BillboardGui"
aq.Parent=am
aq.Name="chest"
aq.StudsOffsetWorldSpace=Vector3.new(0,3,0)
aq.Size=UDim2.fromOffset(36,36)
aq.AlwaysOnTop=true
aq.ClipsDescendants=false
aq.Adornee=an
local ar=addBlur(aq)
ar.Visible=aj.Enabled
local as=Instance.new"Frame"
as.Size=UDim2.fromScale(1,1)
as.BackgroundColor3=Color3.fromHSV(ak.Hue,ak.Sat,ak.Value)
as.BackgroundTransparency=1-(aj.Enabled and ak.Opacity or 0)
as.Parent=aq
local at=Instance.new"UIListLayout"
at.FillDirection=Enum.FillDirection.Horizontal
at.Padding=UDim.new(0,4)
at.VerticalAlignment=Enum.VerticalAlignment.Center
at.HorizontalAlignment=Enum.HorizontalAlignment.Center
at:GetPropertyChangedSignal"AbsoluteContentSize":Connect(function()
aq.Size=UDim2.fromOffset(math.max(at.AbsoluteContentSize.X+4,36),36)
end)
at.Parent=as
local au=Instance.new"UICorner"
au.CornerRadius=UDim.new(0,4)
au.Parent=as
al[an]=aq
ah:Clean(ap.ChildAdded:Connect(function(av)
if table.find(ai.ListEnabled,av.Name)or nearStorageItem(av.Name)then
refreshAdornee(aq)
end
end))
ah:Clean(ap.ChildRemoved:Connect(function(av)
if table.find(ai.ListEnabled,av.Name)or nearStorageItem(av.Name)then
refreshAdornee(aq)
end
end))
task.spawn(refreshAdornee,aq)
end

ah=u.Categories.Render:CreateModule{
Name="ChestESP",
Function=function(an)
if an then
ah:Clean(o:GetInstanceAddedSignal"chest":Connect(Added))
for ap,aq in o:GetTagged"chest"do
task.spawn(Added,aq)
end
else
table.clear(al)
am:ClearAllChildren()
end
end,
Tooltip="Displays items in chests",
}
ai=ah:CreateTextList{
Name="Item",
Function=function()
for an,ap in al do
task.spawn(refreshAdornee,ap)
end
end,
Default={"speed_potion"},
}
aj=ah:CreateToggle{
Name="Background",
Function=function(an)
if ak.Object then
ak.Object.Visible=an
end
for ap,aq in al do
aq.Frame.BackgroundTransparency=1-(an and ak.Opacity or 0)
aq.Blur.Visible=an
end
end,
Default=true,
}
ak=ah:CreateColorSlider{
Name="Background Color",
DefaultValue=0,
DefaultOpacity=0.5,
Function=function(an,ap,aq,ar)
for as,at in al do
at.Frame.BackgroundColor3=Color3.fromHSV(an,ap,aq)
at.Frame.BackgroundTransparency=1-ar
end
end,
Darker=true,
}
end)

b(function()
local ah

ah=u.Categories.Utility:CreateModule{
Name="AutoBalloon",
Function=function(ai)
if ai then
repeat
task.wait()
until F.matchState~=0 or not ah.Enabled
if not ah.Enabled then
return
end

local aj=math.huge
for ak,al in F.blocks do
local am=(al.Position.Y-(al.Size.Y/2))-50
if am<aj then
aj=am
end
end

repeat
if x.isAlive then
if
x.character.RootPart.Position.Y<aj
and(s.Character:GetAttribute"InflatedBalloons"or 0)<3
then
local ak=getItem"balloon"
if ak then
for al=1,3 do
L.BalloonController:inflateBalloon()
end
end
task.wait(0.1)
end
end
task.wait(0.1)
until not ah.Enabled
end
end,
Tooltip="Inflates when you fall into the void",
}
end)

b(function()
local ah
local ai
local aj={}

local function kitCollection(ak,al,am,an)
local ap=type(ak)=="table"and ak or collection(ak,ah)
repeat
if x.isAlive then
local aq=x.character.RootPart.Position
for ar,as in ap do
if I.Enabled or not ah.Enabled then
break
end
local at=not as:IsA"Model"and as or as.PrimaryPart
if
at
and(at.Position-aq).Magnitude
<=(not ai.Enabled and an and math.huge or am)
then
al(as)
end
end
end
task.wait(0.1)
until not ah.Enabled
end

local ak={
battery=function()
repeat
if x.isAlive then
local ak=x.character.RootPart.Position
for al,am in L.BatteryEffectsController.liveBatteries do
if(am.position-ak).Magnitude<=10 then
local an=L.BatteryEffectsController:getBatteryInfo(al)
if
not an
or an.activateTime>=workspace:GetServerTimeNow()
or an.consumeTime+0.1>=workspace:GetServerTimeNow()
then
continue
end
an.consumeTime=workspace:GetServerTimeNow()
L.Client:Get(M.ConsumeBattery):SendToServer{batteryId=al}
end
end
end
task.wait(0.1)
until not ah.Enabled
end,
beekeeper=function()
kitCollection("bee",function(ak)
L.Client:Get(M.BeePickup):SendToServer{beeId=ak:GetAttribute"BeeId"}
end,18,false)
end,
bigman=function()
kitCollection("treeOrb",function(ak)
if
L.Client
:Get(M.ConsumeTreeOrb)
:CallServer{treeOrbSecret=ak:GetAttribute"TreeOrbSecret"}
then
ak:Destroy()
end
end,12,false)
end,
block_kicker=function()
local ak=L.BlockKickerKitController.getKickBlockProjectileOriginPosition
L.BlockKickerKitController.getKickBlockProjectileOriginPosition=function(...)
local al,am=select(2,...)
local an=x.EntityMouse{
Part="RootPart",
Range=1000,
Origin=al,
Players=true,
Wallcheck=true,
}

if an then
local ap=B.SolveTrajectory(
al,
100,
20,
an.RootPart.Position,
an.RootPart.Velocity,
workspace.Gravity,
an.HipHeight,
an.Jumping and 42.6 or nil
)

if ap then
for aq,ar in debug.getstack(2)do
if ar==am then
debug.setstack(2,aq,CFrame.lookAt(al,ap).LookVector)
end
end
end
end

return ak(...)
end

ah:Clean(function()
L.BlockKickerKitController.getKickBlockProjectileOriginPosition=ak
end)
end,
cat=function()
local ak=L.CatController.leap
L.CatController.leap=function(...)
c.CatPounce:Fire()
return ak(...)
end

ah:Clean(function()
L.CatController.leap=ak
end)
end,
davey=function()
local ak=L.CannonHandController.launchSelf
L.CannonHandController.launchSelf=function(...)
local al={ak(...)}local
am, an=...

if
an:GetAttribute"PlacedByUserId"==s.UserId
and(an.Position-x.character.RootPart.Position).Magnitude<30
then
task.spawn(L.breakBlock,an,false,nil,true)
end

return unpack(al)
end

ah:Clean(function()
L.CannonHandController.launchSelf=ak
end)
end,
dragon_slayer=function()
kitCollection("KaliyahPunchInteraction",function(ak)
L.DragonSlayerController:deleteEmblem(ak)
L.DragonSlayerController:playPunchAnimation(Vector3.zero)
L.Client:Get(M.KaliyahPunch):SendToServer{
target=ak,
}
end,18,true)
end,
farmer_cletus=function()
kitCollection("HarvestableCrop",function(ak)
if
L.Client
:Get(M.HarvestCrop)
:CallServer{position=L.BlockController:getBlockPosition(ak.Position)}
then
L.GameAnimationUtil:playAnimation(s.Character,L.AnimationType.PUNCH)
L.SoundManager:playSound(L.SoundList.CROP_HARVEST)
end
end,10,false)
end,
fisherman=function()
local ak=L.FishingMinigameController.startMinigame
L.FishingMinigameController.startMinigame=function(al,am,an,ap)
ak(al,am,function()end,ap)
task.wait(0.3)
an{win=true}
end

ah:Clean(function()
L.FishingMinigameController.startMinigame=ak
end)
end,
gingerbread_man=function()
local ak=L.LaunchPadController.attemptLaunch
L.LaunchPadController.attemptLaunch=function(...)
local al={ak(...)}
local am,an=...

if(workspace:GetServerTimeNow()-am.lastLaunch)<0.4 then
if
an:GetAttribute"PlacedByUserId"==s.UserId
and(an.Position-x.character.RootPart.Position).Magnitude<30
then
task.spawn(L.breakBlock,an,false,nil,true)
end
end

return unpack(al)
end

ah:Clean(function()
L.LaunchPadController.attemptLaunch=ak
end)
end,
hannah=function()
kitCollection("HannahExecuteInteraction",function(ak)
local al=L.Client:Get(M.HannahKill):CallServer{
user=s,
victimEntity=ak,
}and ak:FindFirstChild"Hannah Execution Icon"

if al then
al:Destroy()
end
end,30,true)
end,
jailor=function()
kitCollection("jailor_soul",function(ak)
L.JailorController:collectEntity(s,ak,"JailorSoul")
end,20,false)
end,
grim_reaper=function()
kitCollection(L.GrimReaperController.soulsByPosition,function(ak)
if
x.isAlive
and s.Character:GetAttribute"Health"<=(s.Character:GetAttribute"MaxHealth"/4)
and(not s.Character:GetAttribute"GrimReaperChannel")
then
L.Client:Get(M.ConsumeSoul):CallServer{
secret=ak:GetAttribute"GrimReaperSoulSecret",
}
end
end,120,false)
end,
melody=function()
repeat
local ak,al,am=30,math.huge
if x.isAlive then
local an=x.character.RootPart.Position
for ap,aq in x.List do
if aq.Player and aq.Player:GetAttribute"Team"==s:GetAttribute"Team"then
local ar=(an-aq.RootPart.Position).Magnitude
if ar<=ak and aq.Health<al and aq.Health<aq.MaxHealth then
ak,al,am=ar,aq.Health,aq
end
end
end
end

if am and getItem"guitar"then
L.Client:Get(M.GuitarHeal):SendToServer{
healTarget=am.Character,
}
end

task.wait(0.1)
until not ah.Enabled
end,
metal_detector=function()
kitCollection("hidden-metal",function(ak)
L.Client:Get(M.PickupMetal):SendToServer{
id=ak:GetAttribute"Id",
}
end,20,false)
end,
miner=function()
kitCollection("petrified-player",function(ak)
L.Client:Get(M.MinerDig):SendToServer{
petrifyId=ak:GetAttribute"PetrifyId",
}
end,6,true)
end,
pinata=function()
kitCollection(s.Name..":pinata",function(ak)
if getItem"candy"then
L.Client:Get(M.DepositPinata):CallServer(ak)
end
end,6,true)
end,
spirit_assassin=function()
kitCollection("EvelynnSoul",function(ak)
L.SpiritAssassinController:useSpirit(s,ak)
end,120,true)
end,
star_collector=function()
kitCollection("stars",function(ak)
L.StarCollectorController:collectEntity(s,ak,ak.Name)
end,20,false)
end,
summoner=function()
repeat
local ak=x.EntityPosition{
Range=31,
Part="RootPart",
Players=true,
Sort=V.Health,
}

if ak and(not ai.Enabled or(s.Character:GetAttribute"Health"or 0)>0)then
local al=x.character.RootPart.Position
local am=CFrame.lookAt(al,ak.RootPart.Position).LookVector
al+=am*math.max((al-ak.RootPart.Position).Magnitude-16,0)

L.Client:Get(M.SummonerClawAttack):SendToServer{
position=al,
direction=am,
clientTime=workspace:GetServerTimeNow(),
}
end

task.wait(0.1)
until not ah.Enabled
end,
void_dragon=function()
local ak=L.VoidDragonController.flapWings
local al

L.VoidDragonController.flapWings=function(am)
if not al and L.Client:Get(M.DragonFly):CallServer()then
local an=L.SprintController:getMovementStatusModifier():addModifier{
blockSprint=true,
constantSpeedMultiplier=2,
}
am.SpeedMaid:GiveTask(an)
am.SpeedMaid:GiveTask(function()
al=false
end)
al=true
end
end

ah:Clean(function()
L.VoidDragonController.flapWings=ak
end)

repeat
if L.VoidDragonController.inDragonForm then
local am=x.EntityPosition{
Range=30,
Part="RootPart",
Players=true,
}

if am then
L.Client:Get(M.DragonBreath):SendToServer{
player=s,
targetPoint=am.RootPart.Position,
}
end
end
task.wait(0.1)
until not ah.Enabled
end,
warlock=function()
local ak
repeat
if F.hand.tool and F.hand.tool.Name=="warlock_staff"then
local al=x.EntityPosition{
Range=30,
Part="RootPart",
Players=true,
NPCs=true,
}

if al and al.Character~=ak then
if
not L.Client:Get(M.WarlockTarget):CallServer{
target=al.Character,
}
then
al=nil
end
end

ak=al and al.Character
else
ak=nil
end

task.wait(0.1)
until not ah.Enabled
end,
wizard=function()
repeat
local ak=s:GetAttribute"WizardAbility"
if ak and L.AbilityController:canUseAbility(ak)then
local al=x.EntityPosition{
Range=50,
Part="RootPart",
Players=true,
Sort=V.Health,
}

if al then
L.AbilityController:useAbility(
ak,
newproxy(true),
{target=al.RootPart.Position}
)
end
end

task.wait(0.1)
until not ah.Enabled
end,
}

ah=u.Categories.Utility:CreateModule{
Name="AutoKit",
Function=function(al)
if al then
repeat
task.wait()
until F.equippedKit~=""and F.matchState~=0 or not ah.Enabled
for am,an in
{
wizard="AutoZeno",
fisherman="AutoFish",
metal_detector="AutoMetal",
}
do
if ah.Enabled and F.equippedKit==am and u.Modules[an]and u.Modules[an].Enabled then
warningNotification("AutoKit",`Disabled {tostring(an)} to prevent breaking logic`,3)
pcall(function()
u.Modules[an]:Toggle()
end)
end
end
if ah.Enabled and ak[F.equippedKit]and aj[F.equippedKit].Enabled then
ak[F.equippedKit]()
end
end
end,
Tooltip="Automatically uses kit abilities.",
}
ai=ah:CreateToggle{Name="Legit Range"}
local al={}
for am in ak do
table.insert(al,am)
end
table.sort(al,function(am,an)
return(L.BedwarsKitMeta[am]and L.BedwarsKitMeta[am].name or"")
<(L.BedwarsKitMeta[an]and L.BedwarsKitMeta[an].name or"")
end)
for am,an in al do
aj[an]=ah:CreateToggle{
Name=(L.BedwarsKitMeta[an]and L.BedwarsKitMeta[an].name or tostring(an)),
Default=true,
}
end
end)

b(function()
local ah
local ai=RaycastParams.new()
ai.RespectCanCollide=true
local aj={InvokeServer=function()end}
task.spawn(function()
aj=L.Client:Get(M.FireProjectile).instance
end)

local function firePearl(ak,al,am)
switchItem(am.tool)
local an=L.ProjectileMeta.telepearl
local ap=B.SolveTrajectory(
ak,
an.launchVelocity,
an.gravitationalAcceleration,
al,
Vector3.zero,
workspace.Gravity,
0,
0
)

if ap then
local aq=CFrame.lookAt(ak,ap).LookVector*an.launchVelocity
L.ProjectileController:createLocalProjectile(
an,
"telepearl",
"telepearl",
ak,
nil,
aq,
{drawDurationSeconds=1}
)
aj:InvokeServer(
am.tool,
"telepearl",
"telepearl",
ak,
ak,
aq,
i:GenerateGUID(true),
{drawDurationSeconds=1,shotId=i:GenerateGUID(false)},
workspace:GetServerTimeNow()-0.045
)
end

if F.hand then
switchItem(F.hand.tool)
end
end

ah=u.Categories.Utility:CreateModule{
Name="AutoPearl",
Function=function(ak)
if ak then
local al
repeat
if x.isAlive then
local am=x.character.RootPart
local an=getItem"telepearl"
ai.FilterDescendantsInstances={s.Character,r,K}
ai.CollisionGroup=am.CollisionGroup

if an and am.Velocity.Y<-100 and not blocksRaycast(200)then

if not al then
al=true
local ap=getNearGround(20)

if ap then
firePearl(am.Position,ap,an)
end
end
else
al=false
end
end
task.wait(0.1)
until not ah.Enabled
end
end,
Tooltip="Automatically throws a pearl onto nearby ground after\nfalling a certain distance.",
}
end)

b(function()
local ah
local ai

local function isEveryoneDead()
return#L.Store:getState().Party.members<=0
end

local aj=false
local function joinQueue()
if
not L.Store:getState().Game.customMatch
and L.Store:getState().Party.leader.userId==s.UserId
and L.Store:getState().Party.queueState==0
then
if aj then
return
end
local ak=F.queueType
if ai.Enabled then
local al={}
for am,an in L.QueueMeta do
if not an.disabled and not an.voiceChatOnly and not an.rankCategory then
table.insert(al,am)
end
end
ak=al[math.random(1,#al)]
end
if not ak then
ak=F.queueType
end
local al=ak
local am=L.QueueMeta[ak]
if am and am.title then
al=tostring(am.title)
end
aj=true
InfoNotification("AutoQueue",`Joining queue for {tostring(al)}...`,3)
L.QueueController:joinQueue(ak)
end
end

ah=u.Categories.Utility:CreateModule{
Name="AutoQueue",
Function=function(ak)
aj=false
if ak then
ah:Clean(c.EntityDeathEvent.Event:Connect(function(al)
if
al.finalKill
and al.entityInstance==s.Character
and isEveryoneDead()
and F.matchState~=2
then
joinQueue()
end
end))
ah:Clean(c.MatchEndEvent.Event:Connect(joinQueue))
end
end,
Tooltip="Automatically queues after the match ends.",
}
ai=ah:CreateToggle{
Name="Random",
Tooltip="Chooses a random mode",
}
end)

b(function()
local ah,ai=false

local function getCrossbows()
local aj={}
for ak,al in F.inventory.hotbar do
if al.item and al.item.itemType:find"crossbow"and ak~=(F.inventory.hotbarSlot+1)then
table.insert(aj,ak-1)
end
end
return aj
end

u.Categories.Utility:CreateModule{
Name="AutoShoot",
Function=function(aj)
if aj then
ai=L.ProjectileController.createLocalProjectile
L.ProjectileController.createLocalProjectile=function(...)local
ak, al, am=...
if ak and(am=="arrow"or am=="fireball")and not ah then
task.spawn(function()
local an=getCrossbows()
if#an>0 then
ah=true
task.wait(0.15)
local ap=F.inventory.hotbarSlot
for aq,ar in getCrossbows()do
if hotbarSwitch(ar)then
task.wait(0.05)
mouse1click()
task.wait(0.05)
end
end
hotbarSwitch(ap)
ah=false
end
end)
end
return ai(...)
end
else
L.ProjectileController.createLocalProjectile=ai
end
end,
Tooltip="Automatically crossbow macro's",
}
end)

b(function()
local ah
local ai
local aj,ak,al,am={},{},{}

local function sendMessage(an,ap,aq)
local ar=ak[an].ListEnabled
local as=#ar>0 and ar[math.random(1,#ar)]or aq
if not as then
return
end
if#ar>1 and as==al[an]then
repeat
task.wait()
as=ar[math.random(1,#ar)]
until as~=al[an]
end
al[an]=as

as=as and as:gsub("<obj>",ap or"")or""
if l.ChatVersion==Enum.ChatVersion.TextChatService then
l.ChatInputBarConfiguration.TargetTextChannel:SendAsync(as)
else
n.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(as,"All")
end
end

ah=u.Categories.Utility:CreateModule{
Name="AutoToxic",
Function=function(an)
if an then
ah:Clean(c.BedwarsBedBreak.Event:Connect(function(ap)
if aj.BedDestroyed.Enabled and ap.brokenBedTeam.id==s:GetAttribute"Team"then
sendMessage(
"BedDestroyed",
(ap.player.DisplayName or ap.player.Name),
"how dare you >:( | <obj>"
)
elseif aj.Bed.Enabled and ap.player.UserId==s.UserId then
local aq=L.QueueMeta[F.queueType].teams[tonumber(ap.brokenBedTeam.id)]
sendMessage("Bed",aq and aq.displayName:lower()or"white","nice bed lul | <obj>")
end
end))
ah:Clean(c.EntityDeathEvent.Event:Connect(function(ap)
if ap.finalKill then
local aq=h:GetPlayerFromCharacter(ap.fromEntity)
local ar=h:GetPlayerFromCharacter(ap.entityInstance)
if not ar or not aq then
return
end
if ar==s then
if(not am)and aq~=s and aj.Death.Enabled then
am=true
sendMessage(
"Death",
(aq.DisplayName or aq.Name),
"my gaming chair subscription expired :( | <obj>"
)
end
elseif aq==s and aj.Kill.Enabled then
sendMessage("Kill",(ar.DisplayName or ar.Name),"vxp on top | <obj>")
end
end
end))
ah:Clean(c.MatchEndEvent.Event:Connect(function(ap)
if ai.Enabled then
if l.ChatVersion==Enum.ChatVersion.TextChatService then
l.ChatInputBarConfiguration.TargetTextChannel:SendAsync"gg"
else
n.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("gg","All")
end
end

local aq=L.Store:getState().Game.myTeam
if aq and aq.id==ap.winningTeamId or s.Neutral then
if aj.Win.Enabled then
sendMessage("Win",nil,"yall garbage")
end
end
end))
end
end,
Tooltip="Says a message after a certain action",
}
ai=ah:CreateToggle{
Name="AutoGG",
Default=true,
}
for an,ap in{"Kill","Death","Bed","BedDestroyed","Win"}do
aj[ap]=ah:CreateToggle{
Name=ap.." ",
Function=function(aq)
if ak[ap]then
ak[ap].Object.Visible=aq
end
end,
}
ak[ap]=ah:CreateTextList{
Name=ap,
Darker=true,
Visible=false,
}
end
end)

b(function()
local ah
local ai

ah=u.Categories.Utility:CreateModule{
Name="AutoVoidDrop",
Function=function(aj)
if aj then
repeat
task.wait()
until F.matchState~=0 or not ah.Enabled
if not ah.Enabled then
return
end

local ak=math.huge
for al,am in F.blocks do
local an=(am.Position.Y-(am.Size.Y/2))-50
if an<ak then
ak=an
end
end

repeat
if x.isAlive then
local al=x.character.RootPart
if
al.Position.Y<ak
and(s.Character:GetAttribute"InflatedBalloons"or 0)<=0
and not getItem"balloon"
then
if not ai.Enabled or not al:FindFirstChild"OwlLiftForce"then
for am,an in{"iron","diamond","emerald","gold"}do
an=getItem(an)
if an then
an=L.Client:Get(M.DropItem):CallServer{
item=an.tool,
amount=an.amount,
}

if an then
an:SetAttribute("ClientDropTime",tick()+100)
end
end
end
end
end
end

task.wait(0.1)
until not ah.Enabled
end
end,
Tooltip="Drops resources when you fall into the void",
}
ai=ah:CreateToggle{
Name="Owl check",
Default=true,
Tooltip="Refuses to drop items if being picked up by an owl",
}
end)

b(function()
local ah

ah=u.Categories.Utility:CreateModule{
Name="MissileTP",
Function=function(ai)
if ai then
ah:Toggle()
local aj=x.EntityMouse{
Range=1000,
Players=true,
Part="RootPart",
}

if getItem"guided_missile"and aj then
local ak=L.RuntimeLib.await(
L.GuidedProjectileController.fireGuidedProjectile:CallServerAsync"guided_missile"
)
if ak then
local al=ak.model
if not al.PrimaryPart then
al:GetPropertyChangedSignal"PrimaryPart":Wait()
end

local am=Instance.new"BodyForce"
am.Force=
Vector3.new(0,al.PrimaryPart.AssemblyMass*workspace.Gravity,0)
am.Name="AntiGravity"
am.Parent=al.PrimaryPart

repeat
ak.model:SetPrimaryPartCFrame(
CFrame.lookAlong(aj.RootPart.CFrame.p,r.CFrame.LookVector)
)
task.wait(0.1)
until not ak.model or not ak.model.Parent
else
notif("MissileTP","Missile on cooldown.",3)
end
end
end
end,
Tooltip="Spawns and teleports a missile to a player\nnear your mouse.",
}
end)

b(function()
local ah
local ai
local aj
local ak

ah=u.Categories.Utility:CreateModule{
Name="PickupRange",
Function=function(al)
if al then
local am=collection("ItemDrop",ah)
repeat
if x.isAlive then
local an=x.character.RootPart.Position
for ap,aq in am do
if tick()-(aq:GetAttribute"ClientDropTime"or 0)<2 then
continue
end
if q(aq)and aj.Enabled and x.character.Humanoid.Health>0 then
aq.CFrame=CFrame.new(an-Vector3.new(0,3,0))
end

if(an-aq.Position).Magnitude<=ai.Value then
if
ak.Enabled
and(an.Y-aq.Position.Y)<(x.character.HipHeight-1)
then
continue
end
task.spawn(function()
L.Client
:Get(M.PickupItem)
:CallServerAsync{
itemDrop=aq,
}
:andThen(function(ar)
if ar and L.SoundList then
L.SoundManager:playSound(L.SoundList.PICKUP_ITEM_DROP)
local as=L.ItemMeta[aq.Name].pickUpOverlaySound
if as then
L.SoundManager:playSound(as,{
position=aq.Position,
volumeMultiplier=0.9,
})
end
end
end)
end)
end
end
end
task.wait(0.1)
until not ah.Enabled
end
end,
Tooltip="Picks up items from a farther distance",
}
ai=ah:CreateSlider{
Name="Range",
Min=1,
Max=10,
Default=10,
Suffix=function(al)
return al==1 and"stud"or"studs"
end,
}




aj={Enabled=false}
ak=ah:CreateToggle{Name="Feet Check"}
end)

b(function()
local ah

ah=u.Categories.Utility:CreateModule{
Name="RavenTP",
Function=function(ai)
if ai then
ah:Toggle()
local aj=x.EntityMouse{
Range=1000,
Players=true,
Part="RootPart",
}

if getItem"raven"and aj then
L.Client:Get(M.SpawnRaven):CallServerAsync():andThen(function(ak)
if ak then
local al=Instance.new"BodyForce"
al.Force=Vector3.new(0,ak.PrimaryPart.AssemblyMass*workspace.Gravity,0)
al.Parent=ak.PrimaryPart

if aj then
task.spawn(function()
for am=1,20 do
if aj.RootPart and ak then
ak:SetPrimaryPartCFrame(
CFrame.lookAlong(aj.RootPart.Position,r.CFrame.LookVector)
)
end
task.wait(0.05)
end
end)
task.wait(0.3)
L.RavenController:detonateRaven()
end
end
end)
end
end
end,
Tooltip="Spawns and teleports a raven to a player\nnear your mouse.",
}
end)

b(function()
local ah
local ai
local aj
local ak
local al
local am
local an
local ap,aq,ar={},Vector3.zero

for as=-3,3,3 do
for at=-3,3,3 do
for au=-3,3,3 do
local av=Vector3.new(as,at,au)
if av~=Vector3.zero then
table.insert(ap,av)
end
end
end
end

local function nearCorner(as,at)
local au=as-Vector3.new(3,3,3)
local av=as+Vector3.new(3,3,3)
local aw=as+(at-as).Unit*100
return Vector3.new(
math.clamp(aw.X,au.X,av.X),
math.clamp(aw.Y,au.Y,av.Y),
math.clamp(aw.Z,au.Z,av.Z)
)
end

local function blockProximity(as)
local at,au=60
local av=getBlocksInPoints(
L.BlockController:getBlockPosition(as-Vector3.new(21,21,21)),
L.BlockController:getBlockPosition(as+Vector3.new(21,21,21))
)
for aw,ax in av do
local ay=nearCorner(ax,as)
local az=(as-ay).Magnitude
if az<at then
at,au=az,ay
end
end
table.clear(av)
return au
end

local function checkAdjacent(as)
for at,au in ap do
if getPlacedBlock(as+au)then
return true
end
end
return false
end

local function getScaffoldBlock()
if F.hand.toolType=="block"then
return F.hand.tool.Name,F.hand.amount
elseif not am.Enabled then
local as,at=getWool()
if as then
return as,at
else
for au,av in F.inventory.inventory.items do
if L.ItemMeta[av.itemType].block then
return av.itemType,av.amount
end
end
end
end

return nil,0
end

ah=u.Categories.Utility:CreateModule{
Name="Scaffold",
Function=function(as)
if ar then
ar.Visible=as
end

if as then
repeat
if x.isAlive then
local at,au=getScaffoldBlock()

if an.Enabled then
if not k:IsMouseButtonPressed(0)then
at=nil
end
end

if ar then
au=au or 0
ar.Text=au..' <font color="rgb(170, 170, 170)">(Scaffold)</font>'
ar.TextColor3=Color3.fromHSV((au/128)/2.8,0.86,1)
end

if at then
local av=x.character.RootPart
if
aj.Enabled
and k:IsKeyDown(Enum.KeyCode.Space)
and(not k:GetFocusedTextBox())
then
av.Velocity=Vector3.new(av.Velocity.X,38,av.Velocity.Z)
end

for aw=ai.Value,1,-1 do
local ax=roundPos(
av.Position
-Vector3.new(
0,
x.character.HipHeight
+(
ak.Enabled
and k:IsKeyDown(Enum.KeyCode.LeftShift)
and 4.5
or 1.5
),
0
)
+x.character.Humanoid.MoveDirection*(aw*3)
)
if al.Enabled then
if
math.abs(
math.round(
math.deg(
math.atan2(
-x.character.Humanoid.MoveDirection.X,
-x.character.Humanoid.MoveDirection.Z
)
)/45
)*45
)
%90
==45
then
local ay=(aq-ax)
if
((ay.X==0 and ay.Z~=0)or(ay.X~=0 and ay.Z==0))
and((aq-av.Position)*Vector3.new(1,0,1)).Magnitude<2.5
then
ax=aq
end
end
end

local ay,az=getPlacedBlock(ax)
if not ay then
az=checkAdjacent(az*3)and az*3
or blockProximity(ax)
if az then
task.spawn(L.placeBlock,az,at,false)
end
end
aq=ax
end
end
end

task.wait(0.03)
until not ah.Enabled
else
Label=nil
end
end,
Tooltip="Helps you make bridges/scaffold walk.",
}
ai=ah:CreateSlider{
Name="Expand",
Min=1,
Max=6,
}
aj=ah:CreateToggle{
Name="Tower",
Default=true,
}
ak=ah:CreateToggle{
Name="Downwards",
Default=true,
}
al=ah:CreateToggle{
Name="Diagonal",
Default=true,
}
am=ah:CreateToggle{Name="Limit to items"}
an=ah:CreateToggle{Name="Require mouse down"}
Count=ah:CreateToggle{
Name="Block Count",
Function=function(as)
if as then
ar=Instance.new"TextLabel"
ar.Size=UDim2.fromOffset(100,20)
ar.Position=UDim2.new(0.5,6,0.5,60)
ar.BackgroundTransparency=1
ar.AnchorPoint=Vector2.new(0.5,0)
ar.Text="0"
ar.TextColor3=Color3.new(0,1,0)
ar.TextSize=18
ar.RichText=true
ar.Font=Enum.Font.Arial
ar.Visible=ah.Enabled
ar.Parent=u.gui
else
ar:Destroy()
ar=nil
end
end,
}
end)

b(function()
local ah
local ai,aj={},{}

ah=u.Categories.Utility:CreateModule{
Name="ShopTierBypass",
Function=function(ak)
if ak then
repeat
task.wait()
until F.shopLoaded or not ah.Enabled
if ah.Enabled then
for al,am in L.Shop.ShopItems do
ai[am]=am.tiered
aj[am]=am.nextTier
am.nextTier=nil
am.tiered=nil
end
end
else
for al,am in ai do
al.tiered=am
end
for al,am in aj do
al.nextTier=am
end
table.clear(aj)
table.clear(ai)
end
end,
Tooltip="Lets you buy things like armor early.",
}
end)

b(function()
local ah
local ai
local aj
local ak
local al
local am
local an={"gg","gg2","DV","DV2"}
local ap={
1502104539,
3826146717,
4531785383,
1049767300,
4926350670,
653085195,
184655415,
2752307430,
5087196317,
5744061325,
1536265275,
}
local aq={}

local function getRole(ar,as)
local at,au=pcall(function()
return ar:GetRankInGroup(as)
end)
if not at then
notif("StaffDetector",au,30,"alert")
end
return at and au or 0
end

local function staffFunction(ar,as)
if not u.Loaded then
repeat
task.wait()
until u.Loaded
end

notif(
"StaffDetector",
"Staff Detected ("..as.."): "..ar.Name.." ("..ar.UserId..")",
60,
"alert"
)
z.customtags[ar.Name]={{text="GAME STAFF",color=Color3.new(1,0,0)}}

if ak.Enabled and not as:find"clan"then
L.PartyController:leaveParty()
end

if ai.Value=="Uninject"then
task.spawn(function()
u:Uninject()
end)
game:GetService"StarterGui":SetCore("SendNotification",{
Title="StaffDetector",
Text="Staff Detected ("..as..")\n"..ar.Name.." ("..ar.UserId..")",
Duration=60,
})
elseif ai.Value=="Requeue"then
L.QueueController:joinQueue(F.queueType)
elseif ai.Value=="Profile"then
u.Save=function()end
if u.Profile~=al.Value then
u:Load(true,al.Value)
end
elseif ai.Value=="AutoConfig"then
local at={"AutoClicker","Reach","Sprint","HitFix","StaffDetector"}
u.Save=function()end
for au,av in u.Modules do
if not(table.find(at,au)or av.Category=="Render")then
if av.Enabled then
av:Toggle()
end
av:SetBind""
end
end
end
end

local function checkFriends(ar)
for as,at in ar do
if aq[at]then
return aq[at]
end
end
return nil
end

local function checkJoin(ar,as)
if
not ar:GetAttribute"Team"
and ar:GetAttribute"Spectator"
and not L.Store:getState().Game.customMatch
then
as:Disconnect()
local at,au={},h:GetFriendsAsync(ar.UserId)
for av=1,4 do
for aw,ax in au:GetCurrentPage()do
table.insert(at,ax.Id)
end
if au.IsFinished then
break
end
au:AdvanceToNextPageAsync()
end

local av=checkFriends(at)
if not av then
staffFunction(ar,"impossible_join")
return true
else
notif("StaffDetector",string.format("Spectator %s joined from %s",ar.Name,av),20,"warning")
end
end
end

local function playerAdded(ar)
aq[ar.UserId]=ar.Name
if ar==s then
return
end

if table.find(ap,ar.UserId)or table.find(am.ListEnabled,tostring(ar.UserId))then
staffFunction(ar,"blacklisted_user")
elseif getRole(ar,5774246)>=100 then
staffFunction(ar,"staff_role")
else
local as
as=ar:GetAttributeChangedSignal"Spectator":Connect(function()
checkJoin(ar,as)
end)
ah:Clean(as)
if checkJoin(ar,as)then
return
end

if not ar:GetAttribute"ClanTag"then
ar:GetAttributeChangedSignal"ClanTag":Wait()
end

if table.find(an,ar:GetAttribute"ClanTag")and u.Loaded and aj.Enabled then
as:Disconnect()
staffFunction(ar,"blacklisted_clan_"..ar:GetAttribute"ClanTag":lower())
end
end
end

ah=u.Categories.Utility:CreateModule{
Name="StaffDetector",
Function=function(ar)
if ar then
ah:Clean(h.PlayerAdded:Connect(playerAdded))
for as,at in h:GetPlayers()do
task.spawn(playerAdded,at)
end
else
table.clear(aq)
end
end,
Tooltip="Detects people with a staff rank ingame",
}
ai=ah:CreateDropdown{
Name="Mode",
List={"Uninject","Profile","Requeue","AutoConfig","Notify"},
Function=function(ar)
if al.Object then
al.Object.Visible=ar=="Profile"
end
end,
}
aj=ah:CreateToggle{
Name="Blacklist clans",
Default=true,
}
ak=ah:CreateToggle{
Name="Leave party",
}
al=ah:CreateTextBox{
Name="Profile",
Default="default",
Darker=true,
Visible=false,
}
am=ah:CreateTextList{
Name="Users",
Placeholder="player (userid)",
}

task.spawn(function()
repeat
task.wait(1)
until u.Loaded or u.Loaded==nil
if u.Loaded and not ah.Enabled then
ah:Toggle()
end
end)
end)

b(function()
J=u.Categories.Utility:CreateModule{
Name="TrapDisabler",
Tooltip="Disables Snap Traps",
}
end)

b(function()
u.Categories.World:CreateModule{
Name="Anti-AFK",
Function=function(ah)
if ah then
for ai,aj in getconnections(s.Idled)do
aj:Disconnect()
end

for ai,aj in getconnections(e.Heartbeat)do
if
type(aj.Function)=="function"and table.find(debug.getconstants(aj.Function),M.AfkStatus)
then
aj:Disconnect()
end
end

L.Client:Get(M.AfkStatus):SendToServer{
afk=false,
}
end
end,
Tooltip="Lets you stay ingame without getting kicked",
}
end)

b(function()
local ah
local ai
local aj

local function fixPosition(ak)
return L.BlockController:getBlockPosition(ak)*3
end

ah=u.Categories.World:CreateModule{
Name="AutoSuffocate",
Function=function(ak)
if ak then
repeat
local al=F.hand.toolType=="block"and F.hand.tool.Name
or not aj.Enabled and getWool()

if al then
local am=x.AllPosition{
Part="RootPart",
Range=ai.Value,
Players=true,
}

for an,ap in am do
local aq={}

for ar,as in Enum.NormalId:GetEnumItems()do
as=Vector3.fromNormalId(as)
if as.Y~=0 then
continue
end

as=fixPosition(ap.RootPart.Position+as*2)
if not getPlacedBlock(as)then
table.insert(aq,as)
end
end

if#aq<3 then
table.insert(aq,fixPosition(ap.Head.Position))
table.insert(aq,fixPosition(ap.RootPart.Position-Vector3.new(0,1,0)))

for ar,as in aq do
if not getPlacedBlock(as)then
task.spawn(L.placeBlock,as,al)
break
end
end
end
end
end

task.wait(0.09)
until not ah.Enabled
end
end,
Tooltip="Places blocks on nearby confined entities",
}
ai=ah:CreateSlider{
Name="Range",
Min=1,
Max=20,
Default=20,
Suffix=function(ak)
return ak==1 and"stud"or"studs"
end,
}
aj=ah:CreateToggle{
Name="Limit to Items",
Default=true,
}
end)

b(function()
local ah
local ai,aj

local function switchHotbarItem(ak)
if
ak
and not ak:GetAttribute"NoBreak"
and not ak:GetAttribute("Team"..(s:GetAttribute"Team"or 0).."NoBreak")
then
local al,am=F.tools[L.ItemMeta[ak.Name].block.breakType]
if al then
for an,ap in F.inventory.hotbar do
if ap.item and ap.item.itemType==al.itemType then
am=an-1
break
end
end

if hotbarSwitch(am)then
if k:IsMouseButtonPressed(0)then
aj:Fire()
end
return true
end
end
end
end

ah=u.Categories.World:CreateModule{
Name="AutoTool",
Function=function(ak)
if ak then
aj=Instance.new"BindableEvent"
ah:Clean(aj)
ah:Clean(aj.Event:Connect(function()
p:CallFunction("block-break",Enum.UserInputState.Begin,newproxy(true))
end))
ai=L.BlockBreaker.hitBlock
L.BlockBreaker.hitBlock=function(al,am,an,...)
local ap=al.clientManager:getBlockSelector():getMouseInfo(1,{ray=an})
if switchHotbarItem(ap and ap.target and ap.target.blockInstance or nil)then
return
end
return ai(al,am,an,...)
end
else
L.BlockBreaker.hitBlock=ai
ai=nil
end
end,
Tooltip="Automatically selects the correct tool",
}
end)

b(function()
local ah

local function getBedNear()
local ai=x.isAlive and x.character.RootPart.Position or Vector3.zero
for aj,ak in o:GetTagged"bed"do
if
(ai-ak.Position).Magnitude<20
and ak:GetAttribute("Team"..(s:GetAttribute"Team"or-1).."NoBreak")
then
return ak
end
end
end

local function getBlocks()
local ai={}
for aj,ak in F.inventory.inventory.items do
local al=L.ItemMeta[ak.itemType].block
if al then
table.insert(ai,{ak.itemType,al.health})
end
end
table.sort(ai,function(aj,ak)
return aj[2]>ak[2]
end)
return ai
end

local function getPyramid(ai,aj)
local ak={}
for al=ai,0,-1 do
for am=al,0,-1 do
table.insert(ak,Vector3.new(am,(ai-al),((al+1)-am))*aj)
table.insert(ak,Vector3.new(am*-1,(ai-al),((al+1)-am))*aj)
table.insert(ak,Vector3.new(am,(ai-al),(al-am)*-1)*aj)
table.insert(ak,Vector3.new(am*-1,(ai-al),(al-am)*-1)*aj)
end
end
return ak
end

ah=u.Categories.World:CreateModule{
Name="BedProtector",
Function=function(ai)
if ai then
local aj=getBedNear()
aj=aj and aj.Position or nil
if aj then
for ak,al in getBlocks()do
for am,an in getPyramid(ak,3)do
if not ah.Enabled then
break
end
if getPlacedBlock(aj+an)then
continue
end
L.placeBlock(aj+an,al[1],false)
end
end
if ah.Enabled then
ah:Toggle()
end
else
notif("BedProtector","Unable to locate bed",5)
ah:Toggle()
end
end
end,
Tooltip="Automatically places strong blocks around the bed.",
}
end)

b(function()
local ah
local ai
local aj
local ak
local al,am,an={},{},{}
local ap,aq

for ar=-3,3,3 do
for as=-3,3,3 do
for at=-3,3,3 do
if Vector3.new(ar,as,at)~=Vector3.zero then
table.insert(an,Vector3.new(ar,as,at))
end
end
end
end

local function checkAdjacent(ar)
for as,at in an do
if getPlacedBlock(ar+at)then
return true
end
end
return false
end

local function getPlacedBlocksInPoints(ar,as)
local at,au={},L.BlockController:getStore()
for av=(as.X>ar.X and ar.X or as.X),(as.X>ar.X and as.X or ar.X)do
for aw=(as.Y>ar.Y and ar.Y or as.Y),(as.Y>ar.Y and as.Y or ar.Y)do
for ax=(as.Z>ar.Z and ar.Z or as.Z),(as.Z>ar.Z and as.Z or ar.Z)do
local ay=Vector3.new(av,aw,ax)
local az=au:getBlockAt(ay)
if az and az:GetAttribute"PlacedByUserId"==s.UserId then
at[ay]=az
end
end
end
end
return at
end

local function loadMaterials()
for ar,as in am do
as:Destroy()
end
local ar,as=pcall(function()
return isfile(ai.Value)and i:JSONDecode(readfile(ai.Value))
end)

if ar and as then
local at={}
for au,av in as do
at[av[2] ]=(at[av[2] ]or 0)+1
end

for au,av in at do
local aw=Instance.new"Frame"
aw.Size=UDim2.new(1,0,0,32)
aw.BackgroundTransparency=1
aw.Parent=ah.Children
local ax=Instance.new"ImageLabel"
ax.Size=UDim2.fromOffset(24,24)
ax.Position=UDim2.fromOffset(4,4)
ax.BackgroundTransparency=1
ax.Image=L.getIcon({itemType=au},true)
ax.Parent=aw
local ay=Instance.new"TextLabel"
ay.Size=UDim2.fromOffset(100,32)
ay.Position=UDim2.fromOffset(32,0)
ay.BackgroundTransparency=1
ay.Text=(L.ItemMeta[au]and L.ItemMeta[au].displayName or au)..": "..av
ay.TextXAlignment=Enum.TextXAlignment.Left
ay.TextColor3=y.Text
ay.TextSize=14
ay.FontFace=y.Font
ay.Parent=aw
table.insert(am,aw)
end
table.clear(as)
table.clear(at)
end
end

local function save()
if ap and aq then
local ar=getPlacedBlocksInPoints(ap,aq)
local as={}
ap=ap*3
for at,au in ar do
at=L.BlockController:getBlockPosition(
CFrame.lookAlong(ap,x.character.RootPart.CFrame.LookVector):PointToObjectSpace(at*3)
)*3
table.insert(as,{
{
x=at.X,
y=at.Y,
z=at.Z,
},
au.Name,
})
end
ap,aq=nil,nil
writefile(ai.Value,i:JSONEncode(as))
notif("Schematica","Saved "..getTableSize(ar).." blocks",5)
loadMaterials()
table.clear(ar)
table.clear(as)
else
local ar=L.BlockBreaker.clientManager:getBlockSelector():getMouseInfo(0)
if ar and ar.target then
if ap then
aq=ar.target.blockRef.blockPosition
notif("Schematica","Selected position 2, toggle again near position 1 to save it",3)
else
ap=ar.target.blockRef.blockPosition
notif("Schematica","Selected position 1",3)
end
end
end
end

local function load(ar)
local as=L.BlockBreaker.clientManager:getBlockSelector():getMouseInfo(0)
if as and as.target then
local at=CFrame.new(as.placementPosition*3)
*CFrame.Angles(
0,
math.rad(
math.round(
math.deg(
math.atan2(
-x.character.RootPart.CFrame.LookVector.X,
-x.character.RootPart.CFrame.LookVector.Z
)
)/45
)*45
),
0
)

for au,av in ar do
local aw=L.BlockController:getBlockPosition(
(at*CFrame.new(av[1].x,av[1].y,av[1].z)).p
)*3
if al[aw]then
continue
end
local ax=
L.BlockController:getHandlerRegistry():getHandler(av[2]:find"wool"and getWool()or av[2])
if ax then
local ay=ax:place(aw/3,0)
ay.Transparency=ak.Value
ay.CanCollide=false
ay.Anchored=true
ay.Parent=workspace
al[aw]=ay
end
end
table.clear(ar)

repeat
if x.isAlive then
local au=x.character.RootPart.Position
for av,aw in al do
if(av-au).Magnitude<60 and checkAdjacent(av)then
if not ah.Enabled then
break
end
if not getItem(aw.Name)then
continue
end
L.placeBlock(av,aw.Name,false)
task.delay(0.1,function()
local ax=getPlacedBlock(av)
if ax then
aw:Destroy()
al[av]=nil
end
end)
end
end
end
task.wait()
until getTableSize(al)<=0

if getTableSize(al)<=0 and ah.Enabled then
notif("Schematica","Finished building",5)
ah:Toggle()
end
end
end

ah=u.Categories.World:CreateModule{
Name="Schematica",
Function=function(ar)
if ar then
if not ai.Value:find".json"then
notif("Schematica","Invalid file",3)
ah:Toggle()
return
end

if aj.Value=="Save"then
save()
ah:Toggle()
else
local as,at=pcall(function()
return isfile(ai.Value)and i:JSONDecode(readfile(ai.Value))
end)

if as and at then
load(at)
else
notif("Schematica","Missing / corrupted file",3)
ah:Toggle()
end
end
else
for as,at in al do
at:Destroy()
end
table.clear(al)
end
end,
Tooltip="Save and load placements of buildings",
}
ai=ah:CreateTextBox{
Name="File",
Function=function()
loadMaterials()
ap,aq=nil,nil
end,
}
aj=ah:CreateDropdown{
Name="Mode",
List={"Load","Save"},
}
ak=ah:CreateSlider{
Name="Transparency",
Min=0,
Max=1,
Default=0.7,
Decimal=10,
Function=function(ar)
for as,at in al do
at.Transparency=ar
end
end,
}
end)

b(function()
local ah
local ai
local aj
local ak

ah=u.Categories.Inventory:CreateModule{
Name="ArmorSwitch",
Function=function(al)
if al then
if ai.Value=="Toggle"then
repeat
local am=x.EntityPosition{
Part="RootPart",
Range=ak.Value,
Players=aj.Players.Enabled,
NPCs=aj.NPCs.Enabled,
Wallcheck=aj.Walls.Enabled,
}and true or false

for an=0,2 do
if(F.inventory.inventory.armor[an+1]~="empty")~=am and ah.Enabled then
L.Store:dispatch{
type="InventorySetArmorItem",
item=F.inventory.inventory.armor[an+1]=="empty"
and am
and getBestArmor(an)
or nil,
armorSlot=an,
}
c.InventoryChanged.Event:Wait()
end
end
task.wait(0.1)
until not ah.Enabled
else
ah:Toggle()
for am=0,2 do
L.Store:dispatch{
type="InventorySetArmorItem",
item=F.inventory.inventory.armor[am+1]=="empty"and getBestArmor(am)or nil,
armorSlot=am,
}
c.InventoryChanged.Event:Wait()
end
end
end
end,
Tooltip="Puts on / takes off armor when toggled for baiting.",
}
ai=ah:CreateDropdown{
Name="Mode",
List={"Toggle","On Key"},
}
aj=ah:CreateTargets{
Players=true,
NPCs=true,
}
ak=ah:CreateSlider{
Name="Range",
Min=1,
Max=30,
Default=30,
Suffix=function(al)
return al==1 and"stud"or"studs"
end,
}
end)

b(function()
local ah
local ai
local aj
local ak
local al={}

local function addItem(am,an)
local ap=Instance.new"ImageLabel"
ap.Image=L.getIcon({itemType=am},true)
ap.Size=UDim2.fromOffset(32,32)
ap.Name=am
ap.BackgroundTransparency=1
ap.LayoutOrder=#aj:GetChildren()
ap.Parent=aj
local aq=Instance.new"TextLabel"
aq.Name="Amount"
aq.Size=UDim2.fromScale(1,1)
aq.BackgroundTransparency=1
aq.Text=""
aq.TextColor3=Color3.new(1,1,1)
aq.TextSize=16
aq.TextStrokeTransparency=0.3
aq.Font=Enum.Font.Arial
aq.Parent=ap
al[am]={Object=aq,Type=an}
end

local function refreshBank(am)
for an,ap in al do
local aq=am:FindFirstChild(an)
ap.Object.Text=aq and aq:GetAttribute"Amount"or""
end
end

local function nearChest()
if x.isAlive then
local am=x.character.RootPart.Position
for an,ap in ak do
if(ap.Position-am).Magnitude<20 then
return true
end
end
end
end

local function handleState()
local am=n.Inventories:FindFirstChild(s.Name.."_personal")
if not am then
return
end

local an=workspace.MapCFrames:FindFirstChild((s:GetAttribute"Team"or 1).."_spawn")
if an and(x.character.RootPart.Position-an.Value.Position).Magnitude<80 then
for ap,aq in am:GetChildren()do
local ar=al[aq.Name]
if ar then
task.spawn(function()
L.Client:GetNamespace"Inventory":Get"ChestGetItem":CallServer(am,aq)
refreshBank(am)
end)
end
end
else
for ap,aq in F.inventory.inventory.items do
local ar=al[aq.itemType]
if ar then
task.spawn(function()
L.Client:GetNamespace"Inventory":Get"ChestGiveItem":CallServer(am,aq.tool)
refreshBank(am)
end)
end
end
end
end

ah=u.Categories.Inventory:CreateModule{
Name="AutoBank",
Function=function(am)
if am then
ak=collection("personal-chest",ah)
aj=Instance.new"Frame"
aj.Size=UDim2.new(1,0,0,32)
aj.Position=UDim2.fromOffset(0,-240)
aj.BackgroundTransparency=1
aj.Visible=ai.Enabled
aj.Parent=u.gui
ah:Clean(aj)
local an=Instance.new"UIListLayout"
an.FillDirection=Enum.FillDirection.Horizontal
an.HorizontalAlignment=Enum.HorizontalAlignment.Center
an.SortOrder=Enum.SortOrder.LayoutOrder
an.Parent=aj
addItem("iron",true)
addItem("gold",true)
addItem("diamond",false)
addItem("emerald",true)
addItem("void_crystal",true)

repeat
local ap=s.PlayerGui:FindFirstChild"hotbar"
ap=ap and ap["1"]:FindFirstChild"HotbarHealthbarContainer"
if ap then
aj.Position=UDim2.fromOffset(0,(ap.AbsolutePosition.Y+f:GetGuiInset().Y)-40)
end

local aq=nearChest()
if aq then
handleState()
end

task.wait(0.1)
until not ah.Enabled
else
table.clear(al)
end
end,
Tooltip="Automatically puts resources in ender chest",
}
ai=ah:CreateToggle{
Name="UI",
Function=function(am)
if ah.Enabled then
aj.Visible=am
end
end,
Default=true,
}
end)

b(function()
local ah
local ai
local aj
local ak
local al
local am={}
local an
local ap
local aq={}
local ar={}
local as={}
local at,au={}
local av={aq,at,ar}
local aw=tick()

local ax={
"wood_sword",
"stone_sword",
"iron_sword",
"diamond_sword",
"emerald_sword",
}

local ay={
"none",
"leather_chestplate",
"iron_chestplate",
"diamond_chestplate",
"emerald_chestplate",
}

local az={
"none",
"wood_axe",
"stone_axe",
"iron_axe",
"diamond_axe",
}

local aA={
"none",
"wood_pickaxe",
"stone_pickaxe",
"iron_pickaxe",
"diamond_pickaxe",
}

local function getShopNPC()
local aB,aC,aD,aE=false,false
if x.isAlive then
local aF=x.character.RootPart.Position
for aG,aH in F.shop do
if(aH.RootPart.Position-aF).Magnitude<=20 then
aD=aH.Upgrades or aH.Shop or nil
aC=aC or aH.Upgrades
aB=aB or aH.Shop
aE=aH.Shop and aH.Id or aE
end
end
end
return aD,aB,aC,aE
end

local function canBuy(aB,aC,aD)
aD=aD or 1
if not aC[aB.currency]then
local aE=getItem(aB.currency)
aC[aB.currency]=aE and aE.amount or 0
end
if
aB.ignoredByKit
and(
table.find(aB.ignoredByKit,F.equippedKit or"")
or table.find(aB.ignoredByKit,F.equippedKit2 or"")
)
then
return false
end
if aB.lockedByForge or aB.disabled then
return false
end
if aB.require and aB.require.teamUpgrade then
if
(L.Store:getState().Bedwars.teamUpgrades[aB.require.teamUpgrade.upgradeId]or-1)
<aB.require.teamUpgrade.lowestTierIndex
then
return false
end
end
return aC[aB.currency]>=(aB.price*aD)
end

local function buyItem(aB,aC)
if not au then
return
end
notif("AutoBuy","Bought "..L.ItemMeta[aB.itemType].displayName,3)
L.Client
:Get"BedwarsPurchaseItem"
:CallServerAsync{
shopItem=aB,
shopId=au,
}
:andThen(function(aD)
if aD then
L.SoundManager:playSound(L.SoundList.BEDWARS_PURCHASE_ITEM)
L.Store:dispatch{
type="BedwarsAddItemPurchased",
itemType=aB.itemType,
}
L.BedwarsShopController.alreadyPurchasedMap[aB.itemType]=true
end
end)
aC[aB.currency]-=aB.price
end

local function buyUpgrade(aB,aC)
if not ak.Enabled then
return
end
local aD=L.TeamUpgradeMeta[aB]
local aE=L.Store:getState().Bedwars.teamUpgrades[s:GetAttribute"Team"]or{}
local aF=(aE[aB]or 0)+1
local aG=false

for aH=aF,#aD.tiers do
local aI=aD.tiers[aH]
if aI.availableOnlyInQueue and not table.find(aI.availableOnlyInQueue,F.queueType)then
continue
end

if canBuy({currency="diamond",price=aI.cost},aC)then
notif("AutoBuy","Bought "..(aD.name=="Armor"and"Protection"or aD.name).." "..aH,3)
L.Client:Get"RequestPurchaseTeamUpgrade":CallServerAsync(aB)
aC.diamond-=aI.cost
aG=true
else
break
end
end

return aG
end

local function buyTool(aB,aC,aD)
if not(aC~=nil and type(aC)=="table")then
warn"Couldn't process buyTool!"
return false
end
local aE,aF=false
aB=aB and table.find(aC,aB.itemType)and table.find(aC,aB.itemType)+1 or math.huge

for aG=aB,#aC do
local aH=L.Shop.getShopItem(aC[aG],s)
if canBuy(aH,aD)then
if ap.Enabled and L.ItemMeta[aC[aG] ].breakBlock and aG>2 then
if aj.Enabled then
local aI=F.inventory.inventory.armor[2]
aI=aI and aI~="empty"and aI.itemType or"none"
if(table.find(ay,aI)or 3)<3 then
break
end
end
if ai.Enabled then
if F.tools.sword and(table.find(ax,F.tools.sword.itemType)or 2)<2 then
break
end
end
end
aE=true
aF=aH
end
if al.Enabled and aH.nextTier then
break
end
end

if aF then
buyItem(aF,aD)
end

return aE
end

ah=u.Categories.Inventory:CreateModule{
Name="AutoBuy",
Function=function(aB)
if aB then
repeat
task.wait()
until F.queueType~="bedwars_test"
if am.Enabled and not F.queueType:find"bedwars"then
return
end

local aC
ah:Clean(c.InventoryAmountChanged.Event:Connect(function()
if(aw-tick())>1 then
aw=tick()
end
end))

repeat
local aD,aE,aF,aG=getShopNPC()
au=aG
if an.Enabled then
if
not(
L.AppController:isAppOpen"BedwarsItemShopApp"
or L.AppController:isAppOpen"TeamUpgradeApp"
)
then
aD=nil
end
end

if aD and aC~=aF then
if(aw-tick())>1 then
aw=tick()
end
aC=aF
end

if aD and aw<=tick()and F.matchState~=2 and F.shopLoaded then
local aH={}
local aI
local aJ,aK=pcall(function()
for aJ,aK in av do
for aL,aM in aK do
if aM(aH,aE,aF)then
aI=true
end
end
end
end)
if not aJ then
warn(aK)
end
aw=tick()+(aI and 0.4 or math.huge)
end

task.wait(0.1)
until not ah.Enabled
else
aw=tick()
end
end,
Tooltip="Automatically buys items when you go near the shop",
}
ai=ah:CreateToggle{
Name="Buy Sword",
Function=function(aB)
aw=tick()
at[2]=aB
and function(aC,aD)
if not aD then
return
end

if L.isKitEquipped"dasher"then
ax={
[1]="wood_dao",
[2]="stone_dao",
[3]="iron_dao",
[4]="diamond_dao",
[5]="emerald_dao",
}
elseif L.isKitEquipped"ice_queen"then
ax[5]="ice_sword"
elseif L.isKitEquipped"ember"then
ax[5]="infernal_saber"
elseif L.isKitEquipped"lumen"then
ax[5]="light_sword"
end

return buyTool(F.tools.sword,ax,aC)
end
or nil
end,
}
aj=ah:CreateToggle{
Name="Buy Armor",
Function=function(aB)
aw=tick()
at[1]=aB
and function(aC,aD)
if not aD then
return
end
local aE=F.inventory.inventory.armor[2]~="empty"
and F.inventory.inventory.armor[2]
or getBestArmor(1)
aE=aE and aE.itemType or"none"
return buyTool({itemType=aE},ay,aC)
end
or nil
end,
Default=true,
}
ah:CreateToggle{
Name="Buy Axe",
Function=function(aB)
aw=tick()
at[3]=aB
and function(aC,aD)
if not aD then
return
end
return buyTool(F.tools.wood or{itemType="none"},az,aC)
end
or nil
end,
}
ah:CreateToggle{
Name="Buy Pickaxe",
Function=function(aB)
aw=tick()
at[4]=aB
and function(aC,aD)
if not aD then
return
end
return buyTool(F.tools.stone,aA,aC)
end
or nil
end,
}
ak=ah:CreateToggle{
Name="Buy Upgrades",
Function=function(aB)
for aC,aD in as do
aD.Object.Visible=aB
end
end,
Default=true,
}
local aB=0
for aC,aD in L.TeamUpgradeMeta do
local aE=aB
table.insert(
as,
ah:CreateToggle{
Name="Buy "..(aD.name=="Armor"and"Protection"or aD.name),
Function=function(aF)
aw=tick()
at[5+aE+(aD.name=="Armor"and 20 or 0)]=aF
and function(aG,aH,aI)
if not aI then
return
end
if aD.disabledInQueue and table.find(aD.disabledInQueue,F.queueType)then
return
end
return buyUpgrade(aC,aG)
end
or nil
end,
Darker=true,
Default=(aC=="ARMOR"or aC=="DAMAGE"),
}
)
aB+=1
end
al=ah:CreateToggle{Name="Tier Check"}
am=ah:CreateToggle{
Name="Only Bedwars",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
Default=true,
}
an=ah:CreateToggle{Name="GUI check"}
ap=ah:CreateToggle{
Name="Smart check",
Default=true,
Tooltip="Buys iron armor before iron axe",
}
ah:CreateTextList{
Name="Item",
Placeholder="priority/item/amount/after",
Function=function(aC)
table.clear(aq)
table.clear(ar)
for aD,aE in aC do
local aF=aE:split"/"
local aG=tonumber(aF[1])
if aG then
(aF[4]and ar or aq)[aG]=function(aH,aI)
if not aI then
return
end

local aJ=L.Shop.getShopItem(aF[2],s)
if aJ then
local aK=getItem(
aF[2]=="wool_white"and L.Shop.getTeamWool(s:GetAttribute"Team")or aF[2]
)
aK=(aK and tonumber(aF[3])-aK.amount or tonumber(aF[3]))//aJ.amount
if aK>0 and canBuy(aJ,aH,aK)then
for aL=1,aK do
buyItem(aJ,aH)
end
return true
end
end
end
end
end
end,
}
end)














































































































b(function()
local ah
local ai
local aj
local ak
local al

local function consumeCheck(am)
if x.isAlive then
if aj.Enabled and(not am or am=="StatusEffect_speed")then
local an=getItem"speed_potion"
if an and(not s.Character:GetAttribute"StatusEffect_speed")then
for ap=1,4 do
if L.Client:Get(M.ConsumeItem):CallServer{item=an.tool}then
break
end
end
end
end

if ak.Enabled and(not am or am:find"Health")then
if
(s.Character:GetAttribute"Health"/s.Character:GetAttribute"MaxHealth")
<=(ai.Value/100)
then
local an=getItem"orange"
or(not s.Character:GetAttribute"StatusEffect_golden_apple"and getItem"golden_apple")
or getItem"apple"

if an then
L.Client:Get(M.ConsumeItem):CallServerAsync{
item=an.tool,
}
end
end
end

if al.Enabled and(not am or am:find"Shield")then
if(s.Character:GetAttribute"Shield_POTION"or 0)==0 then
local an=getItem"big_shield"or getItem"mini_shield"

if an then
L.Client:Get(M.ConsumeItem):CallServerAsync{
item=an.tool,
}
end
end
end
end
end

ah=u.Categories.Inventory:CreateModule{
Name="AutoConsume",
Function=function(am)
if am then
ah:Clean(c.InventoryAmountChanged.Event:Connect(consumeCheck))
ah:Clean(c.AttributeChanged.Event:Connect(function(an)
if an:find"Shield"or an:find"Health"or an=="StatusEffect_speed"then
consumeCheck(an)
end
end))
consumeCheck()
end
end,
Tooltip="Automatically heals for you when health or shield is under threshold.",
}
ai=ah:CreateSlider{
Name="Health Percent",
Min=1,
Max=99,
Default=70,
Suffix="%",
}
aj=ah:CreateToggle{
Name="Speed Potions",
Default=true,
}
ak=ah:CreateToggle{
Name="Apple",
Default=true,
}
al=ah:CreateToggle{
Name="Shield Potions",
Default=true,
}
end)

b(function()
local ah
local ai
local aj
local ak
local al

local function CreateWindow(am)
local an=1
local ap=Instance.new"Frame"
ap.Name="HotbarGUI"
ap.Size=UDim2.fromOffset(660,465)
ap.Position=UDim2.fromScale(0.5,0.5)
ap.BackgroundColor3=y.Main
ap.AnchorPoint=Vector2.new(0.5,0.5)
ap.Visible=false
ap.Parent=u.gui.ScaledGui
local aq=Instance.new"TextLabel"
aq.Name="Title"
aq.Size=UDim2.new(1,-10,0,20)
aq.Position=UDim2.fromOffset(math.abs(aq.Size.X.Offset),12)
aq.BackgroundTransparency=1
aq.Text="AutoHotbar"
aq.TextXAlignment=Enum.TextXAlignment.Left
aq.TextColor3=y.Text
aq.TextSize=13
aq.FontFace=y.Font
aq.Parent=ap
local ar=Instance.new"Frame"
ar.Name="Divider"
ar.Size=UDim2.new(1,0,0,1)
ar.Position=UDim2.fromOffset(0,40)
ar.BackgroundColor3=w.Light(y.Main,0.04)
ar.BorderSizePixel=0
ar.Parent=ap
addBlur(ap)
local as=Instance.new"TextButton"
as.Text=""
as.BackgroundTransparency=1
as.Modal=true
as.Parent=ap
local at=Instance.new"UICorner"
at.CornerRadius=UDim.new(0,5)
at.Parent=ap
local au=Instance.new"ImageButton"
au.Name="Close"
au.Size=UDim2.fromOffset(24,24)
au.Position=UDim2.new(1,-35,0,9)
au.BackgroundColor3=Color3.new(1,1,1)
au.BackgroundTransparency=1
au.Image=E"newvape/assets/new/close.png"
au.ImageColor3=w.Light(y.Text,0.2)
au.ImageTransparency=0.5
au.AutoButtonColor=false
au.Parent=ap
au.MouseEnter:Connect(function()
au.ImageTransparency=0.3
v:Tween(au,TweenInfo.new(0.2),{
BackgroundTransparency=0.6,
})
end)
au.MouseLeave:Connect(function()
au.ImageTransparency=0.5
v:Tween(au,TweenInfo.new(0.2),{
BackgroundTransparency=1,
})
end)
au.MouseButton1Click:Connect(function()
ap.Visible=false
u.gui.ScaledGui.ClickGui.Visible=true
end)
local av=Instance.new"UICorner"
av.CornerRadius=UDim.new(1,0)
av.Parent=au
local aw=Instance.new"Frame"
aw.Size=UDim2.fromOffset(110,111)
aw.Position=UDim2.fromOffset(11,71)
aw.BackgroundColor3=w.Dark(y.Main,0.02)
aw.Parent=ap
local ax=Instance.new"UICorner"
ax.CornerRadius=UDim.new(0,4)
ax.Parent=aw
local ay=Instance.new"UIStroke"
ay.Color=w.Light(y.Main,0.034)
ay.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
ay.Parent=aw
local az=Instance.new"TextLabel"
az.Size=UDim2.fromOffset(80,20)
az.Position=UDim2.fromOffset(25,200)
az.BackgroundTransparency=1
az.Text="SLOT 1"
az.TextColor3=w.Dark(y.Text,0.1)
az.TextSize=12
az.FontFace=y.Font
az.Parent=ap
for aA=1,9 do
local aB=Instance.new"TextButton"
aB.Name="Slot"..aA
aB.Size=UDim2.fromOffset(51,52)
aB.Position=UDim2.fromOffset(89+(aA*55),382)
aB.BackgroundColor3=w.Dark(y.Main,0.02)
aB.Text=""
aB.AutoButtonColor=false
aB.Parent=ap
local aC=Instance.new"ImageLabel"
aC.Size=UDim2.fromOffset(32,32)
aC.Position=UDim2.new(0.5,-16,0.5,-16)
aC.BackgroundTransparency=1
aC.Image=""
aC.Parent=aB
local aD=Instance.new"UICorner"
aD.CornerRadius=UDim.new(0,4)
aD.Parent=aB
local aE=Instance.new"UIStroke"
aE.Color=w.Light(y.Main,0.04)
aE.Thickness=2
aE.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
aE.Enabled=aA==an
aE.Parent=aB
aB.MouseEnter:Connect(function()
aB.BackgroundColor3=w.Light(y.Main,0.034)
end)
aB.MouseLeave:Connect(function()
aB.BackgroundColor3=w.Dark(y.Main,0.02)
end)
aB.MouseButton1Click:Connect(function()
ap["Slot"..an].UIStroke.Enabled=false
an=aA
aE.Enabled=true
az.Text="SLOT "..an
end)
aB.MouseButton2Click:Connect(function()
local aF=am.Hotbars[am.Selected]
if aF then
ap["Slot"..aA].ImageLabel.Image=""
aF.Hotbar[tostring(aA)]=nil
aF.Object["Slot"..aA].Image="	"
end
end)
end
local aA=Instance.new"Frame"
aA.Size=UDim2.fromOffset(496,31)
aA.Position=UDim2.fromOffset(142,80)
aA.BackgroundColor3=w.Light(y.Main,0.034)
aA.Parent=ap
local aB=Instance.new"TextBox"
aB.Size=UDim2.new(1,-10,0,31)
aB.Position=UDim2.fromOffset(10,0)
aB.BackgroundTransparency=1
aB.Text=""
aB.PlaceholderText=""
aB.TextXAlignment=Enum.TextXAlignment.Left
aB.TextColor3=y.Text
aB.TextSize=12
aB.FontFace=y.Font
aB.ClearTextOnFocus=false
aB.Parent=aA
local aC=Instance.new"UICorner"
aC.CornerRadius=UDim.new(0,4)
aC.Parent=aA
local aD=Instance.new"ImageLabel"
aD.Size=UDim2.fromOffset(14,14)
aD.Position=UDim2.new(1,-26,0,8)
aD.BackgroundTransparency=1
aD.Image=E"newvape/assets/new/search.png"
aD.ImageColor3=w.Light(y.Main,0.37)
aD.Parent=aA
local aE=Instance.new"ScrollingFrame"
aE.Name="Children"
aE.Size=UDim2.fromOffset(500,240)
aE.Position=UDim2.fromOffset(144,122)
aE.BackgroundTransparency=1
aE.BorderSizePixel=0
aE.ScrollBarThickness=2
aE.ScrollBarImageTransparency=0.75
aE.CanvasSize=UDim2.new()
aE.Parent=ap
local aF=Instance.new"UIGridLayout"
aF.SortOrder=Enum.SortOrder.LayoutOrder
aF.FillDirectionMaxCells=9
aF.CellSize=UDim2.fromOffset(51,52)
aF.CellPadding=UDim2.fromOffset(4,3)
aF.Parent=aE
aF:GetPropertyChangedSignal"AbsoluteContentSize":Connect(function()
if u.ThreadFix then
setthreadidentity(8)
end
aE.CanvasSize=UDim2.fromOffset(0,aF.AbsoluteContentSize.Y/u.guiscale.Scale)
end)
table.insert(u.Windows,ap)

local function createitem(aG,aH)
local aI=Instance.new"TextButton"
aI.BackgroundColor3=w.Light(y.Main,0.02)
aI.Text=""
aI.AutoButtonColor=false
aI.Parent=aE
local aJ=Instance.new"ImageLabel"
aJ.Size=UDim2.fromOffset(32,32)
aJ.Position=UDim2.new(0.5,-16,0.5,-16)
aJ.BackgroundTransparency=1
aJ.Image=aH
aJ.Parent=aI
local aK=Instance.new"UICorner"
aK.CornerRadius=UDim.new(0,4)
aK.Parent=aI
aI.MouseEnter:Connect(function()
aI.BackgroundColor3=w.Light(y.Main,0.04)
end)
aI.MouseLeave:Connect(function()
aI.BackgroundColor3=w.Light(y.Main,0.02)
end)
aI.MouseButton1Click:Connect(function()
local aL=am.Hotbars[am.Selected]
if aL then
ap["Slot"..an].ImageLabel.Image=aH
aL.Hotbar[tostring(an)]=aG
aL.Object["Slot"..an].Image=aH
end
end)
end

local function indexSearch(aG)
for aH,aI in aE:GetChildren()do
if aI:IsA"TextButton"then
aI:ClearAllChildren()
aI:Destroy()
end
end

if aG==""then
for aH,aI in
{
"diamond_sword",
"diamond_pickaxe",
"diamond_axe",
"shears",
"wood_bow",
"wool_white",
"fireball",
"apple",
"iron",
"gold",
"diamond",
"emerald",
}
do
createitem(aI,L.ItemMeta[aI].image)
end
return
end

for aH,aI in L.ItemMeta do
if aG:lower()==aH:lower():sub(1,aG:len())then
if not aI.image then
continue
end
createitem(aH,aI.image)
end
end
end

aB:GetPropertyChangedSignal"Text":Connect(function()
indexSearch(aB.Text)
end)
indexSearch""

return ap
end

u.Components.HotbarList=function(am,an,ap)
if u.ThreadFix then
setthreadidentity(8)
end
local aq={
Type="HotbarList",
Hotbars={},
Selected=1,
}
local ar=Instance.new"TextButton"
ar.Name="HotbarList"
ar.Size=UDim2.fromOffset(220,40)
ar.BackgroundColor3=am.Darker
and(an.BackgroundColor3==w.Dark(y.Main,0.02)and w.Dark(y.Main,0.04)or w.Dark(
y.Main,
0.02
))
or an.BackgroundColor3
ar.Text=""
ar.BorderSizePixel=0
ar.AutoButtonColor=false
ar.Parent=an
local as=Instance.new"Frame"
as.Name="BKG"
as.Size=UDim2.new(1,-20,0,31)
as.Position=UDim2.fromOffset(10,4)
as.BackgroundColor3=w.Light(y.Main,0.034)
as.Parent=ar
local at=Instance.new"UICorner"
at.CornerRadius=UDim.new(0,4)
at.Parent=as
local au=Instance.new"TextButton"
au.Name="HotbarList"
au.Size=UDim2.new(1,-2,1,-2)
au.Position=UDim2.fromOffset(1,1)
au.BackgroundColor3=y.Main
au.Text=""
au.AutoButtonColor=false
au.Parent=as
au.MouseEnter:Connect(function()
v:Tween(as,TweenInfo.new(0.2),{
BackgroundColor3=w.Light(y.Main,0.14),
})
end)
au.MouseLeave:Connect(function()
v:Tween(as,TweenInfo.new(0.2),{
BackgroundColor3=w.Light(y.Main,0.034),
})
end)
local av=Instance.new"UICorner"
av.CornerRadius=UDim.new(0,4)
av.Parent=au
local aw=Instance.new"ImageLabel"
aw.Size=UDim2.fromOffset(12,12)
aw.Position=UDim2.fromScale(0.5,0.5)
aw.AnchorPoint=Vector2.new(0.5,0.5)
aw.BackgroundTransparency=1
aw.Image=E"newvape/assets/new/add.png"
aw.ImageColor3=Color3.fromHSV(0.46,0.96,0.52)
aw.Parent=au
local ax=Instance.new"Frame"
ax.Size=UDim2.new(1,0,1,-40)
ax.Position=UDim2.fromOffset(0,40)
ax.BackgroundTransparency=1
ax.Parent=ar
local ay=Instance.new"UIListLayout"
ay.SortOrder=Enum.SortOrder.LayoutOrder
ay.HorizontalAlignment=Enum.HorizontalAlignment.Center
ay.Padding=UDim.new(0,3)
ay.Parent=ax
ay:GetPropertyChangedSignal"AbsoluteContentSize":Connect(function()
if u.ThreadFix then
setthreadidentity(8)
end
ar.Size=
UDim2.fromOffset(220,math.min(43+ay.AbsoluteContentSize.Y/u.guiscale.Scale,603))
end)
au.MouseButton1Click:Connect(function()
aq:AddHotbar()
end)
aq.Window=CreateWindow(aq)

function aq.Save(az,aA)
local aB={}
for aC,aD in az.Hotbars do
table.insert(aB,aD.Hotbar)
end
aA.HotbarList={
Selected=az.Selected,
Hotbars=aB,
}
end

function aq.Load(az,aA)
for aB,aC in az.Hotbars do
aC.Object:ClearAllChildren()
aC.Object:Destroy()
table.clear(aC.Hotbar)
end
table.clear(az.Hotbars)
for aB,aC in aA.Hotbars do
az:AddHotbar(aC)
end
az.Selected=aA.Selected or 1
end

function aq.AddHotbar(az,aA)
local aB={Hotbar=aA or{}}
table.insert(az.Hotbars,aB)
local aC=Instance.new"TextButton"
aC.Size=UDim2.fromOffset(200,27)
aC.BackgroundColor3=table.find(az.Hotbars,aB)==az.Selected
and w.Light(y.Main,0.034)
or y.Main
aC.Text=""
aC.AutoButtonColor=false
aC.Parent=ax
aB.Object=aC
local aD=Instance.new"UICorner"
aD.CornerRadius=UDim.new(0,4)
aD.Parent=aC
for aE=1,9 do
local aF=Instance.new"ImageLabel"
aF.Name="Slot"..aE
aF.Size=UDim2.fromOffset(17,18)
aF.Position=UDim2.fromOffset(-7+(aE*18),5)
aF.BackgroundColor3=w.Dark(y.Main,0.02)
aF.Image=aB.Hotbar[tostring(aE)]
and L.getIcon({itemType=aB.Hotbar[tostring(aE)]},true)
or""
aF.BorderSizePixel=0
aF.Parent=aC
end
aC.MouseButton1Click:Connect(function()
local aE=table.find(aq.Hotbars,aB)
if aE==aq.Selected then
u.gui.ScaledGui.ClickGui.Visible=false
aq.Window.Visible=true
for aF=1,9 do
aq.Window["Slot"..aF].ImageLabel.Image=aB.Hotbar[tostring(aF)]
and L.getIcon({itemType=aB.Hotbar[tostring(aF)]},true)
or""
end
else
if aq.Hotbars[aq.Selected]then
aq.Hotbars[aq.Selected].Object.BackgroundColor3=y.Main
end
aC.BackgroundColor3=w.Light(y.Main,0.034)
aq.Selected=aE
end
end)
local aE=Instance.new"ImageButton"
aE.Name="Close"
aE.Size=UDim2.fromOffset(16,16)
aE.Position=UDim2.new(1,-23,0,6)
aE.BackgroundColor3=Color3.new(1,1,1)
aE.BackgroundTransparency=1
aE.Image=E"newvape/assets/new/closemini.png"
aE.ImageColor3=w.Light(y.Text,0.2)
aE.ImageTransparency=0.5
aE.AutoButtonColor=false
aE.Parent=aC
local aF=Instance.new"UICorner"
aF.CornerRadius=UDim.new(1,0)
aF.Parent=aE
aE.MouseEnter:Connect(function()
aE.ImageTransparency=0.3
v:Tween(aE,TweenInfo.new(0.2),{
BackgroundTransparency=0.6,
})
end)
aE.MouseLeave:Connect(function()
aE.ImageTransparency=0.5
v:Tween(aE,TweenInfo.new(0.2),{
BackgroundTransparency=1,
})
end)
aE.MouseButton1Click:Connect(function()
local aG=table.find(az.Hotbars,aB)
local aH=az.Hotbars[az.Selected]
local aI=az.Hotbars[aG]
if aH and aI then
aI.Object:ClearAllChildren()
aI.Object:Destroy()
table.remove(az.Hotbars,aG)
aG=table.find(az.Hotbars,aH)
az.Selected=table.find(az.Hotbars,aH)or 1
end
end)
end

ap.Options.HotbarList=aq

return aq
end

local function getBlock()
local am=table.clone(F.inventory.inventory.items)
table.sort(am,function(an,ap)
return an.amount<ap.amount
end)

for an,ap in am do
local aq=L.ItemMeta[ap.itemType].block
if aq and not aq.seeThrough then
return ap
end
end
end

local function getCustomItem(am)
if am=="diamond_sword"then
local an=F.tools.sword
am=an and an.itemType or"wood_sword"
elseif am=="diamond_pickaxe"then
local an=F.tools.stone
am=an and an.itemType or"wood_pickaxe"
elseif am=="diamond_axe"then
local an=F.tools.wood
am=an and an.itemType or"wood_axe"
elseif am=="wood_bow"then
local an=getBow()
am=an and an.itemType or"wood_bow"
elseif am=="wool_white"then
local an=getBlock()
am=an and an.itemType or"wool_white"
end

return am
end

local function findItemInTable(am,an)
for ap,aq in am do
if an.itemType==getCustomItem(aq)then
return tonumber(ap)
end
end
end

local function findInHotbar(am)
for an,ap in F.inventory.hotbar do
if ap.item and ap.item.itemType==am.itemType then
return an-1,ap.item
end
end
end

local function findInInventory(am)
for an,ap in F.inventory.inventory.items do
if ap.itemType==am.itemType then
return ap
end
end
end

local function dispatch(...)
L.Store:dispatch(...)
c.InventoryChanged.Event:Wait()
end

local function sortCallback()
if al then
return
end
al=true
local am=(ak.Hotbars[ak.Selected]and ak.Hotbars[ak.Selected].Hotbar or{})

for an,ap in F.inventory.inventory.items do
local aq=findItemInTable(am,ap)
if aq then
local ar=F.inventory.hotbar[aq]
if ar.item and ar.item.itemType==ap.itemType then
continue
end
if ar.item then
dispatch{
type="InventoryRemoveFromHotbar",
slot=aq-1,
}
end

local as=findInHotbar(ap)
if as then
dispatch{
type="InventoryRemoveFromHotbar",
slot=as,
}
if ar.item then
dispatch{
type="InventoryAddToHotbar",
item=findInInventory(ar.item),
slot=as,
}
end
end

dispatch{
type="InventoryAddToHotbar",
item=findInInventory(ap),
slot=aq-1,
}
elseif aj.Enabled then
local ar=findInHotbar(ap)
if ar then
dispatch{
type="InventoryRemoveFromHotbar",
slot=ar,
}
end
end
end

al=false
end

ah=u.Categories.Inventory:CreateModule{
Name="AutoHotbar",
Function=function(am)
if am then
task.spawn(sortCallback)
if ai.Value=="On Key"then
ah:Toggle()
return
end

ah:Clean(c.InventoryAmountChanged.Event:Connect(sortCallback))
end
end,
Tooltip="Automatically arranges hotbar to your liking.",
}
ai=ah:CreateDropdown{
Name="Activation",
List={"Toggle","On Key"},
Function=function()
if not ah then
return
end
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
}
aj=ah:CreateToggle{Name="Clear Hotbar"}
ak=ah:CreateHotbarList{}
end)

b(function()
local ah
local ai,aj

local ak=u.Categories.Inventory:CreateModule{
Name="FastConsume",
Function=function(ak)
if ak then
ai=L.ClickHold.startClick
aj=L.ClickHold.showProgress
L.ClickHold.startClick=function(al)
al.startedClickTime=tick()
local am=al:showProgress()
local an=al.startedClickTime
L.RuntimeLib.Promise.defer(function()
task.wait(al.durationSeconds*(ah.Value/40))
if am==al.handle and an==al.startedClickTime and al.closeOnComplete then
al:hideProgress()
if al.onComplete then
al.onComplete()
end
if al.onPartialComplete then
al.onPartialComplete(1)
end
al.startedClickTime=-1
end
end)
end

L.ClickHold.showProgress=function(al)
local am=debug.getupvalue(aj,1)
local an=am.mount(
am.createElement(
"ScreenGui",
{},
{
am.createElement(
"Frame",
{
[am.Ref]=al.wrapperRef,
Size=UDim2.new(),
Position=UDim2.fromScale(0.5,0.55),
AnchorPoint=Vector2.new(0.5,0),
BackgroundColor3=Color3.fromRGB(0,0,0),
BackgroundTransparency=0.8,
},
{
am.createElement("Frame",{
[am.Ref]=al.progressRef,
Size=UDim2.fromScale(0,1),
BackgroundColor3=Color3.new(1,1,1),
BackgroundTransparency=0.5,
}),
}
),
}
),
s:FindFirstChild"PlayerGui"
)

al.handle=an
local ap=j:Create(al.wrapperRef:getValue(),TweenInfo.new(0.1),{
Size=UDim2.fromScale(0.11,0.005),
})
local aq=j:Create(
al.progressRef:getValue(),
TweenInfo.new(al.durationSeconds*(ah.Value/100),Enum.EasingStyle.Linear),
{
Size=UDim2.fromScale(1,1),
}
)

ap:Play()
aq:Play()
table.insert(al.tweens,aq)
table.insert(al.tweens,ap)

return an
end
else
L.ClickHold.startClick=ai
L.ClickHold.showProgress=aj
ai=nil
aj=nil
end
end,
Tooltip="Use/Consume items quicker.",
}
ah=ak:CreateSlider{
Name="Multiplier",
Min=0,
Max=100,
}
end)

b(function()
local ah

ah=u.Categories.Inventory:CreateModule{
Name="FastDrop",
Function=function(ai)
if ai then
repeat
if
x.isAlive
and not F.inventory.opened
and(k:IsKeyDown(Enum.KeyCode.H)or k:IsKeyDown(Enum.KeyCode.Backspace))
and k:GetFocusedTextBox()==nil
then
task.spawn(L.ItemDropController.dropItemInHand)
task.wait()
else
task.wait(0.1)
end
until not ah.Enabled
end
end,
Tooltip="Drops items fast when you hold Q",
}
end)

b(function()
local ah
local ai
local aj={}
local ak={}
local al=Instance.new"Folder"
al.Parent=u.gui

local function scanSide(am,an,ap)
for aq,ar in N do
for as=1,15 do
local at=getPlacedBlock(an+(ar*as))
if not at or at==am then
break
end
if not at:GetAttribute"NoBreak"and not table.find(ap,at.Name)then
table.insert(ap,at.Name)
end
end
end
end

local function refreshAdornee(am)
for an,ap in am.Frame:GetChildren()do
if ap:IsA"ImageLabel"and ap.Name~="Blur"then
ap:Destroy()
end
end

local an=am.Adornee.Position
local ap={}
scanSide(am.Adornee,an,ap)
scanSide(am.Adornee,an+Vector3.new(0,0,3),ap)
table.sort(ap,function(aq,ar)
return(L.ItemMeta[aq].block and L.ItemMeta[aq].block.health or 0)
>(L.ItemMeta[ar].block and L.ItemMeta[ar].block.health or 0)
end)
am.Enabled=#ap>0

for aq,ar in ap do
local as=Instance.new"ImageLabel"
as.Size=UDim2.fromOffset(32,32)
as.BackgroundTransparency=1
as.Image=L.getIcon({itemType=ar},true)
as.Parent=am.Frame
end
end

local function Added(am)
local an=Instance.new"BillboardGui"
an.Parent=al
an.Name="bed"
an.StudsOffsetWorldSpace=Vector3.new(0,3,0)
an.Size=UDim2.fromOffset(36,36)
an.AlwaysOnTop=true
an.ClipsDescendants=false
an.Adornee=am
local ap=addBlur(an)
ap.Visible=ai.Enabled
local aq=Instance.new"Frame"
aq.Size=UDim2.fromScale(1,1)
aq.BackgroundColor3=Color3.fromHSV(aj.Hue,aj.Sat,aj.Value)
aq.BackgroundTransparency=1-(ai.Enabled and aj.Opacity or 0)
aq.Parent=an
local ar=Instance.new"UIListLayout"
ar.FillDirection=Enum.FillDirection.Horizontal
ar.Padding=UDim.new(0,4)
ar.VerticalAlignment=Enum.VerticalAlignment.Center
ar.HorizontalAlignment=Enum.HorizontalAlignment.Center
ar:GetPropertyChangedSignal"AbsoluteContentSize":Connect(function()
an.Size=UDim2.fromOffset(math.max(ar.AbsoluteContentSize.X+4,36),36)
end)
ar.Parent=aq
local as=Instance.new"UICorner"
as.CornerRadius=UDim.new(0,4)
as.Parent=aq
ak[am]=an
refreshAdornee(an)
end

local function refreshNear(am)
am=am.blockRef.blockPosition*3
for an,ap in ak do
if(am-an.Position).Magnitude<=30 then
refreshAdornee(ap)
end
end
end

ah=u.Categories.Minigames:CreateModule{
Name="BedPlates",
Function=function(am)
if am then
for an,ap in o:GetTagged"bed"do
task.spawn(Added,ap)
end
ah:Clean(c.PlaceBlockEvent.Event:Connect(refreshNear))
ah:Clean(c.BreakBlockEvent.Event:Connect(refreshNear))
ah:Clean(o:GetInstanceAddedSignal"bed":Connect(Added))
ah:Clean(o:GetInstanceRemovedSignal"bed":Connect(function(an)
if ak[an]then
ak[an]:Destroy()
ak[an]:ClearAllChildren()
ak[an]=nil
end
end))
else
table.clear(ak)
al:ClearAllChildren()
end
end,
Tooltip="Displays blocks over the bed",
}
ai=ah:CreateToggle{
Name="Background",
Function=function(am)
if aj.Object then
aj.Object.Visible=am
end
for an,ap in ak do
ap.Frame.BackgroundTransparency=1-(am and aj.Opacity or 0)
ap.Blur.Visible=am
end
end,
Default=true,
}
aj=ah:CreateColorSlider{
Name="Background Color",
DefaultValue=0,
DefaultOpacity=0.5,
Function=function(am,an,ap,aq)
for ar,as in ak do
as.Frame.BackgroundColor3=Color3.fromHSV(am,an,ap)
as.Frame.BackgroundTransparency=1-aq
end
end,
Darker=true,
}
end)

b(function()
local ah
local ai
local aj
local ak
local al
local am
local an
local ap
local aq
local ar={}
local as
local at
local au
local av
local aw,ax={},{}

local function customHealthbar(ay,az,aA,aB,aC,aD)
if aD:GetAttribute"NoHealthbar"then
return
end
if
not ay.healthbarPart
or not ay.healthbarBlockRef
or ay.healthbarBlockRef.blockPosition~=az.blockPosition
then
ay.healthbarMaid:DoCleaning()
ay.healthbarBlockRef=az
local aE=L.Roact.createElement
local aF=math.clamp(aA/aB,0,1)
local aG=true
local aH=Instance.new"Part"
aH.Size=Vector3.one
aH.CFrame=CFrame.new(L.BlockController:getWorldPosition(az.blockPosition))
aH.Transparency=1
aH.Anchored=true
aH.CanCollide=false
aH.Parent=workspace
ay.healthbarPart=aH
L.QueryUtil:setQueryIgnored(ay.healthbarPart,true)

local aI=L.Roact.mount(
aE("BillboardGui",{
Size=UDim2.fromOffset(249,102),
StudsOffset=Vector3.new(0,2.5,0),
Adornee=aH,
MaxDistance=40,
AlwaysOnTop=true,
},{
aE("Frame",{
Size=UDim2.fromOffset(160,50),
Position=UDim2.fromOffset(44,32),
BackgroundColor3=Color3.new(),
BackgroundTransparency=0.5,
},{
aE("UICorner",{CornerRadius=UDim.new(0,5)}),
aE("ImageLabel",{
Size=UDim2.new(1,89,1,52),
Position=UDim2.fromOffset(-48,-31),
BackgroundTransparency=1,
Image=E"newvape/assets/new/blur.png",
ScaleType=Enum.ScaleType.Slice,
SliceCenter=Rect.new(52,31,261,502),
}),
aE("TextLabel",{
Size=UDim2.fromOffset(145,14),
Position=UDim2.fromOffset(13,12),
BackgroundTransparency=1,
Text=L.ItemMeta[aD.Name].displayName or aD.Name,
TextXAlignment=Enum.TextXAlignment.Left,
TextYAlignment=Enum.TextYAlignment.Top,
TextColor3=Color3.new(),
TextScaled=true,
Font=Enum.Font.Arial,
}),
aE("TextLabel",{
Size=UDim2.fromOffset(145,14),
Position=UDim2.fromOffset(12,11),
BackgroundTransparency=1,
Text=L.ItemMeta[aD.Name].displayName or aD.Name,
TextXAlignment=Enum.TextXAlignment.Left,
TextYAlignment=Enum.TextYAlignment.Top,
TextColor3=w.Dark(y.Text,0.16),
TextScaled=true,
Font=Enum.Font.Arial,
}),
aE("Frame",{
Size=UDim2.fromOffset(138,4),
Position=UDim2.fromOffset(12,32),
BackgroundColor3=y.Main,
},{
aE("UICorner",{CornerRadius=UDim.new(1,0)}),
aE("Frame",{
[L.Roact.Ref]=ay.healthbarProgressRef,
Size=UDim2.fromScale(aF,1),
BackgroundColor3=Color3.fromHSV(math.clamp(aF/2.5,0,1),0.89,0.75),
},{aE("UICorner",{CornerRadius=UDim.new(1,0)})}),
}),
}),
}),
aH
)

ay.healthbarMaid:GiveTask(function()
aG=false
ay.healthbarBlockRef=nil
L.Roact.unmount(aI)
if ay.healthbarPart then
ay.healthbarPart:Destroy()
end
ay.healthbarPart=nil
end)

L.RuntimeLib.Promise.delay(5):andThen(function()
if aG then
ay.healthbarMaid:DoCleaning()
end
end)
end

local aE=math.clamp((aA-aC)/aB,0,1)
j
:Create(ay.healthbarProgressRef:getValue(),TweenInfo.new(0.3),{
Size=UDim2.fromScale(aE,1),
BackgroundColor3=Color3.fromHSV(math.clamp(aE/2.5,0,1),0.89,0.75),
})
:Play()
end

local ay=0

local function attemptBreak(az,aA)
if not az then
return
end
if F.matchState==2 then
return
end
for aB,aC in az do
if
(aC.Position-aA).Magnitude<ai.Value
and L.BlockController:isBlockBreakable({blockPosition=aC.Position/3},s)
then
if not at.Enabled and aC:GetAttribute"PlacedByUserId"==s.UserId then
continue
end
if(aC:GetAttribute"BedShieldEndTime"or 0)>workspace:GetServerTimeNow()then
continue
end
if
av.Enabled and not(F.hand.tool and L.ItemMeta[F.hand.tool.Name].breakBlock)
then
continue
end

ay+=1
local aD,aE,aF=L.breakBlock(
aC,
aq.Enabled,
as.Enabled,
ar.Enabled and customHealthbar or nil,
au.Enabled
)
if aE then
local aG=aD
for aH,aI in ax do
aI.Position=aG or Vector3.zero
if aG then
aI.BoxHandleAdornment.Color3=aG==aF and Color3.new(1,0.2,0.2)
or aG==aD and Color3.new(0.2,0.2,1)
or Color3.new(0.2,1,0.2)
end
aG=aE[aG]
end
end

task.wait(au.Enabled and(F.damageBlockFail>tick()and 4.5 or 0)or aj.Value)

return true
end
end

return false
end

ah=u.Categories.Minigames:CreateModule{
Name="Nuker",
Function=function(az)
if az then
for aA=1,30 do
local aB=Instance.new"Part"
aB.Anchored=true
aB.CanQuery=false
aB.CanCollide=false
aB.Transparency=1
aB.Parent=r
local aC=Instance.new"BoxHandleAdornment"
aC.Size=Vector3.one
aC.AlwaysOnTop=true
aC.ZIndex=1
aC.Transparency=0.5
aC.Adornee=aB
aC.Parent=aB
table.insert(ax,aB)
end

local aA=collection("bed",ah)
local aB={}
for aC,aD in
{
"NewYearsLuckyBlock",
"HalloweenLuckyBlock",
"GrowingHalloweenLuckyBlock",
"ForgeLuckyBlock",
"LuckyBlock",
"GlitchedLuckyBlock",
"MagicalHeroLuckyBlock",
}
do
collection(aD,ah,function(aE,aF)
table.insert(aB,aF)
end,function(aE,aF)
local aG=table.find(aB,aF)
if aG then
table.remove(aB,aG)
end
end)
end
local aC=collection("iron_ore_mesh_block",ah)
aw=collection("block",ah,function(aD,aE)
if table.find(al.ListEnabled,aE.Name)then
table.insert(aD,aE)
end
end)

repeat
task.wait(1/ak.Value)
if not ah.Enabled then
break
end
if x.isAlive then
local aD=x.character.RootPart.Position

if attemptBreak(am.Enabled and aA,aD)then
continue
end
if attemptBreak(aw,aD)then
continue
end
if attemptBreak(an.Enabled and aB,aD)then
continue
end
if attemptBreak(ap.Enabled and aC,aD)then
continue
end

for aE,aF in ax do
aF.Position=Vector3.zero
end
end
until not ah.Enabled
else
for aA,aB in ax do
aB:ClearAllChildren()
aB:Destroy()
end
table.clear(ax)
end
end,
Tooltip="Break blocks around you automatically",
}
ai=ah:CreateSlider{
Name="Break range",
Min=1,
Max=30,
Default=30,
Suffix=function(az)
return az==1 and"stud"or"studs"
end,
}
aj=ah:CreateSlider{
Name="Break speed",
Min=0,
Max=0.3,
Default=0.25,
Decimal=100,
Suffix="seconds",
}
ak=ah:CreateSlider{
Name="Update rate",
Min=1,
Max=120,
Default=60,
Suffix="hz",
}
al=ah:CreateTextList{
Name="Custom",
Function=function()
if not aw then
return
end
table.clear(aw)
for az,aA in F.blocks do
if table.find(al.ListEnabled,aA.Name)then
table.insert(aw,aA)
end
end
end,
}
am=ah:CreateToggle{
Name="Break Bed",
Default=true,
}
an=ah:CreateToggle{
Name="Break Lucky Block",
Default=true,
}
ap=ah:CreateToggle{
Name="Break Iron Ore",
Default=true,
}
aq=ah:CreateToggle{
Name="Show Healthbar & Effects",
Function=function(az)
if ar.Object then
ar.Object.Visible=az
end
end,
Default=true,
}
ar=ah:CreateToggle{
Name="Custom Healthbar",
Default=true,
Darker=true,
}
as=ah:CreateToggle{Name="Animation"}
at=ah:CreateToggle{Name="Self Break"}
au=ah:CreateToggle{Name="Instant Break"}
av=ah:CreateToggle{
Name="Limit to items",
Tooltip="Only breaks when tools are held",
}
end)

b(function()
local ah

local ai
local aj={}

ah=u.Legit:CreateModule{
Name="Bed Break Effect",
Function=function(ak)
if ak then
ah:Clean(c.BedwarsBedBreak.Event:Connect(function(al)
firesignal(L.Client:Get"BedBreakEffectTriggered".instance.OnClientEvent,{
player=al.player,
position=al.bedBlockPosition*3,
effectType=aj[ai.Value],
teamId=al.brokenBedTeam.id,
centerBedPosition=al.bedBlockPosition*3,
})
end))
end
end,
Tooltip="Custom bed break effects",
}
local ak={}
for al,am in L.BedBreakEffectMeta do
table.insert(ak,am.name)
aj[am.name]=al
end
table.sort(ak)
ai=ah:CreateDropdown{
Name="Effect",
List=ak,
}
end)

b(function()
u.Legit:CreateModule{
Name="Clean Kit",
Function=function(ah)
if ah then
L.WindWalkerController.spawnOrb=function()end
local ai=s.PlayerGui:FindFirstChild("WindWalkerEffect",true)
if ai then
ai.Visible=false
end
end
end,
Tooltip="Removes zephyr status indicator",
}
end)

b(function()
local ah
local ai

local aj=u.Legit:CreateModule{
Name="Crosshair",
Function=function(aj)
if aj then
ah=debug.getconstant(L.ViewmodelController.showCrosshair,25)
debug.setconstant(L.ViewmodelController.showCrosshair,25,ai.Value)
debug.setconstant(L.ViewmodelController.showCrosshair,37,ai.Value)
else
debug.setconstant(L.ViewmodelController.showCrosshair,25,ah)
debug.setconstant(L.ViewmodelController.showCrosshair,37,ah)
ah=nil
end

if L.ViewmodelController.crosshair then
L.ViewmodelController:hideCrosshair()
L.ViewmodelController:showCrosshair()
end
end,
Tooltip="Custom first person crosshair depending on the image choosen.",
}
ai=aj:CreateTextBox{
Name="Image",
Placeholder="image id (roblox)",
Function=function(ak)
if ak and aj.Enabled then
aj:Toggle()
aj:Toggle()
end
end,
}
end)

b(function()
local ah
local ai
local aj
local ak
local al
local am
local an,ap=pcall(function()
return debug.getupvalue(L.DamageIndicator,2)
end)
ap=an and ap or{}
local aq,ar={}

ah=u.Legit:CreateModule{
Name="Damage Indicator",
Function=function(as)
if as then
aq=table.clone(ap)
ar=debug.getconstant(L.DamageIndicator,86)
debug.setconstant(L.DamageIndicator,86,Enum.Font[ai.Value])
debug.setconstant(L.DamageIndicator,119,am.Enabled and"Thickness"or"Enabled")
ap.strokeThickness=am.Enabled and 1 or false
ap.textSize=ak.Value
ap.blowUpSize=ak.Value
ap.blowUpDuration=0
ap.baseColor=Color3.fromHSV(aj.Hue,aj.Sat,aj.Value)
ap.blowUpCompleteDuration=0
ap.anchoredDuration=al.Value
else
for at,au in aq do
ap[at]=au
end
debug.setconstant(L.DamageIndicator,86,ar)
debug.setconstant(L.DamageIndicator,119,"Thickness")
end
end,
Tooltip="Customize the damage indicator",
}
local as={"GothamBlack"}
for at,au in Enum.Font:GetEnumItems()do
if au.Name~="GothamBlack"then
table.insert(as,au.Name)
end
end
ai=ah:CreateDropdown{
Name="Font",
List=as,
Function=function(at)
if ah.Enabled then
debug.setconstant(L.DamageIndicator,86,Enum.Font[at])
end
end,
}
aj=ah:CreateColorSlider{
Name="Color",
DefaultHue=0,
Function=function(at,au,av)
if ah.Enabled then
ap.baseColor=Color3.fromHSV(at,au,av)
end
end,
}
ak=ah:CreateSlider{
Name="Size",
Min=1,
Max=32,
Default=32,
Function=function(at)
if ah.Enabled then
ap.textSize=at
ap.blowUpSize=at
end
end,
}
al=ah:CreateSlider{
Name="Anchor",
Min=0,
Max=1,
Decimal=10,
Function=function(at)
if ah.Enabled then
ap.anchoredDuration=at
end
end,
}
am=ah:CreateToggle{
Name="Stroke",
Function=function(at)
if ah.Enabled then
debug.setconstant(L.DamageIndicator,119,at and"Thickness"or"Enabled")
ap.strokeThickness=at and 1 or false
end
end,
}
end)

b(function()
local ah
local ai
local aj,ak

ah=u.Legit:CreateModule{
Name="FOV",
Function=function(al)
if al then
aj=L.FovController.setFOV
ak=L.FovController.getFOV
L.FovController.setFOV=function(am)
return aj(am,ai.Value)
end
L.FovController.getFOV=function()
return ai.Value
end
r.FieldOfView=ai.Value
else
L.FovController.setFOV=aj
L.FovController.getFOV=ak
end

L.FovController:setFOV(L.Store:getState().Settings.fov)
end,
Tooltip="Adjusts camera vision",
}
ai=ah:CreateSlider{
Name="FOV",
Min=30,
Max=120,
}
end)

b(function()
local ah
local ai
local aj
local ak,al={},{}

ah=u.Legit:CreateModule{
Name="FPS Boost",
Function=function(am)
if am then
if ai.Enabled then
for an,ap in L.KillEffectController.killEffects do
if not an:find"Custom"then
ak[an]=ap
L.KillEffectController.killEffects[an]={
new=function()
return{
onKill=function()end,
isPlayDefaultKillEffect=function()
return true
end,
}
end,
}
end
end
end

if aj.Enabled then
for an,ap in L.VisualizerUtils do
al[an]=ap
L.VisualizerUtils[an]=function()end
end
end

repeat
task.wait()
until F.matchState~=0
if not L.AppController then
return
end
L.NametagController.addGameNametag=function()end
for an,ap in L.AppController:getOpenApps()do
if tostring(ap):find"Nametag"then
L.AppController:closeApp(tostring(ap))
end
end
else
for an,ap in ak do
L.KillEffectController.killEffects[an]=ap
end
for an,ap in al do
L.VisualizerUtils[an]=ap
end
table.clear(ak)
table.clear(al)
end
end,
Tooltip="Improves the framerate by turning off certain effects",
}
ai=ah:CreateToggle{
Name="Kill Effects",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
Default=true,
}
aj=ah:CreateToggle{
Name="Visualizer",
Function=function()
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
Default=true,
}
end)

b(function()
local ah
local ai
local aj={}

ah=u.Legit:CreateModule{
Name="Hit Color",
Function=function(ak)
if ak then
repeat
for al,am in x.List do
local an=am.Character and am.Character:FindFirstChild"_DamageHighlight_"
if an then
if not table.find(aj,an)then
table.insert(aj,an)
end
an.FillColor=Color3.fromHSV(ai.Hue,ai.Sat,ai.Value)
an.FillTransparency=ai.Opacity
end
end
task.wait(0.1)
until not ah.Enabled
else
for al,am in aj do
am.FillColor=Color3.new(1,0,0)
am.FillTransparency=0.4
end
table.clear(aj)
end
end,
Tooltip="Customize the hit highlight options",
}
ai=ah:CreateColorSlider{
Name="Color",
DefaultOpacity=0.4,
}
u:setupguicolorsync(ah,{
Color1=ai,
Default=true,
})
end)

b(function()
local ah
local ai=
require(s.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-open-inventory"]).HotbarOpenInventory
local aj=
require(s.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar["hotbar-healthbar"]).HotbarHealthbar
local ak=
getRoactRender(require(s.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-app"]).HotbarApp.render)
local al,am={},{}

u:Clean(function()
for an,ap in am do
table.clear(ap)
end
for an,ap in al do
table.clear(ap)
end
table.clear(am)
table.clear(al)
end)

local function modifyconstant(an,ap,aq)
if not an then
return
end
if not al[an]then
al[an]={}
end
if not am[an]then
am[an]={}
end
if not al[an][ap]then
al[an][ap]=debug.getconstant(an,ap)
end
if typeof(al[an][ap])~=typeof(aq)then
return
end
am[an][ap]=aq

if ah.Enabled then
if aq then
debug.setconstant(an,ap,aq)
else
debug.setconstant(an,ap,al[an][ap])
al[an][ap]=nil
end
end
end

ah=u.Legit:CreateModule{
Name="Interface",
Function=function(an)
for ap,aq in(an and am or al)do
for ar,as in aq do
debug.setconstant(ap,ar,as)
end
end
end,
Tooltip="Customize bedwars UI",
}
local an={"LuckiestGuy"}
for ap,aq in Enum.Font:GetEnumItems()do
if aq.Name~="LuckiestGuy"then
table.insert(an,aq.Name)
end
end
ah:CreateDropdown{
Name="Health Font",
List=an,
Function=function(ap)
modifyconstant(aj.render,77,ap)
end,
}
ah:CreateColorSlider{
Name="Health Color",
Function=function(ap,aq,ar)
modifyconstant(aj.render,16,tonumber(Color3.fromHSV(ap,aq,ar):ToHex(),16))
if ah.Enabled then
local as=s.PlayerGui:FindFirstChild"hotbar"
as=as and as:FindFirstChild("HealthbarProgressWrapper",true)
if as then
as["1"].BackgroundColor3=Color3.fromHSV(ap,aq,ar)
end
end
end,
}
ah:CreateColorSlider{
Name="Hotbar Color",
DefaultOpacity=0.8,
Function=function(ap,aq,ar,as)
local at=O or ai.render
modifyconstant(
debug.getupvalue(ak,23).render,
51,
tonumber(Color3.fromHSV(ap,aq,ar):ToHex(),16)
)
modifyconstant(
debug.getupvalue(ak,23).render,
58,
tonumber(Color3.fromHSV(ap,aq,math.clamp(ar>0.5 and ar-0.2 or ar+0.2,0,1)):ToHex(),16)
)
modifyconstant(debug.getupvalue(ak,23).render,54,1-as)
modifyconstant(debug.getupvalue(ak,23).render,55,math.clamp(1.2-as,0,1))
modifyconstant(at,31,tonumber(Color3.fromHSV(ap,aq,ar):ToHex(),16))
modifyconstant(at,32,math.clamp(1.2-as,0,1))
modifyconstant(
at,
34,
tonumber(Color3.fromHSV(ap,aq,math.clamp(ar>0.5 and ar-0.2 or ar+0.2,0,1)):ToHex(),16)
)
end,
}
end)

b(function()
local ah
local ai
local aj
local ak={}

local as={
Gravity=function(al,am,an,ap)
an:BreakJoints()
local aq=an:FindFirstChildWhichIsA"Highlight"
local ar=an:FindFirstChild("Nametag",true)
if aq then
aq:Destroy()
end
if ar then
ar:Destroy()
end

task.spawn(function()
local as={}
for at,au in an:GetDescendants()do
if au:IsA"BasePart"then
as[au.Name]=au.Velocity
end
end
an.Archivable=true
local at=an:Clone()
at.Humanoid.Health=100
at.Parent=workspace
game:GetService"Debris":AddItem(at,30)
an:Destroy()
task.wait(0.01)
at.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
at:BreakJoints()
task.wait(0.01)
for au,av in at:GetDescendants()do
if av:IsA"BasePart"then
local aw=Instance.new"BodyForce"
aw.Force=Vector3.new(0,(workspace.Gravity-10)*av:GetMass(),0)
aw.Parent=av
av.CanCollide=true
av.Velocity=as[av.Name]or Vector3.zero
end
end
end)
end,
Lightning=function(an,ap,aq,ar)
aq:BreakJoints()
local as=aq:FindFirstChildWhichIsA"Highlight"
if as then
as:Destroy()
end
local at=1125
local au=aq.PrimaryPart.CFrame.p-Vector3.new(0,8,0)
local av=Vector3.new((math.random(1,10)-5)*2,at,(math.random(1,10)-5)*2)

for aw=at-75,0,-75 do
local ax=Vector3.new((math.random(1,10)-5)*2,aw,(math.random(1,10)-5)*2)
if aw==0 then
ax=Vector3.zero
end
local ay=Instance.new"Part"
ay.Size=Vector3.new(1.5,1.5,77)
ay.Material=Enum.Material.SmoothPlastic
ay.Anchored=true
ay.Material=Enum.Material.Neon
ay.CanCollide=false
ay.CFrame=CFrame.new(au+av+((ax-av)*0.5),au+ax)
ay.Parent=workspace
local az=ay:Clone()
az.Size=Vector3.new(3,3,78)
az.Color=Color3.new(0.7,0.7,0.7)
az.Transparency=0.7
az.Material=Enum.Material.SmoothPlastic
az.Parent=workspace
game:GetService"Debris":AddItem(ay,0.5)
game:GetService"Debris":AddItem(az,0.5)
L.QueryUtil:setQueryIgnored(ay,true)
L.QueryUtil:setQueryIgnored(az,true)
if aw==0 then
local aA=Instance.new"Part"
aA.Transparency=1
aA.Anchored=true
aA.Size=Vector3.zero
aA.Position=au
aA.Parent=workspace
L.QueryUtil:setQueryIgnored(aA,true)
local aB=Instance.new"Sound"
aB.SoundId="rbxassetid://6993372814"
aB.Volume=2
aB.Pitch=0.5+(math.random(1,3)/10)
aB.Parent=aA
aB:Play()
aB.Ended:Connect(function()
aA:Destroy()
end)
end
av=ax
end
end,
Delete=function(aq,ar,as,at)
as:Destroy()
end,
}

ah=u.Legit:CreateModule{
Name="Kill Effect",
Function=function(at)
if at then
for au,av in as do
L.KillEffectController.killEffects["Custom"..au]={
new=function()
return{
onKill=av,
isPlayDefaultKillEffect=function()
return false
end,
}
end,
}
end
ah:Clean(s:GetAttributeChangedSignal"KillEffectType":Connect(function()
s:SetAttribute(
"KillEffectType",
ai.Value=="Bedwars"and ak[aj.Value]or"Custom"..ai.Value
)
end))
s:SetAttribute(
"KillEffectType",
ai.Value=="Bedwars"and ak[aj.Value]or"Custom"..ai.Value
)
else
for au in as do
L.KillEffectController.killEffects["Custom"..au]=nil
end
s:SetAttribute("KillEffectType","default")
end
end,
Tooltip="Custom final kill effects",
}
local at={"Bedwars"}
for au in as do
table.insert(at,au)
end
ai=ah:CreateDropdown{
Name="Mode",
List=at,
Function=function(au)
aj.Object.Visible=au=="Bedwars"
if ah.Enabled then
s:SetAttribute("KillEffectType",au=="Bedwars"and ak[aj.Value]or"Custom"..au)
end
end,
}
local au={}
for av,aw in L.KillEffectMeta do
table.insert(au,aw.name)
ak[aw.name]=av
end
table.sort(au)
aj=ah:CreateDropdown{
Name="Bedwars",
List=au,
Function=function(av)
if ah.Enabled then
s:SetAttribute("KillEffectType",ak[av])
end
end,
Darker=true,
}
end)

b(function()
local ah
local ai

ah=u.Legit:CreateModule{
Name="Reach Display",
Function=function(aj)
if aj then
repeat
ai.Text=(F.attackReachUpdate>tick()and F.attackReach or"0.00").." studs"
task.wait(0.4)
until not ah.Enabled
end
end,
Size=UDim2.fromOffset(100,41),
}
ah:CreateFont{
Name="Font",
Blacklist="Gotham",
Function=function(aj)
ai.FontFace=aj
end,
}
ah:CreateColorSlider{
Name="Color",
DefaultValue=0,
DefaultOpacity=0.5,
Function=function(aj,ak,as,at)
ai.BackgroundColor3=Color3.fromHSV(aj,ak,as)
ai.BackgroundTransparency=1-at
end,
}
ai=Instance.new"TextLabel"
ai.Size=UDim2.fromScale(1,1)
ai.BackgroundTransparency=0.5
ai.TextSize=15
ai.Font=Enum.Font.Gotham
ai.Text="0.00 studs"
ai.TextColor3=Color3.new(1,1,1)
ai.BackgroundColor3=Color3.new()
ai.Parent=ah.Children
local aj=Instance.new"UICorner"
aj.CornerRadius=UDim.new(0,4)
aj.Parent=ai
end)

b(function()
local ah
local ai
local aj
local ak={}
local as
local at={}
local au=tick()
local av,aw,ax,ay

local function choosesong()
local az=ai.ListEnabled
if#at>=#az then
table.clear(at)
end

if#az<=0 then
notif("SongBeats","no songs",10)
ah:Toggle()
return
end

local aA=az[math.random(1,#az)]
if#az>1 and table.find(at,aA)then
repeat
task.wait()
aA=az[math.random(1,#az)]
until not table.find(at,aA)or not ah.Enabled
end
if not ah.Enabled then
return
end

local aB=aA:split"/"
if not isfile(aB[1])then
notif("SongBeats","Missing song ("..aB[1]..")",10)
ah:Toggle()
return
end

aw.SoundId=t(aB[1])
repeat
task.wait()
until aw.IsLoaded or not ah.Enabled
if ah.Enabled then
au=tick()+(tonumber(aB[3])or 0)
ax=60/(tonumber(aB[2])or 50)
aw:Play()
end
end

ah=u.Legit:CreateModule{
Name="Song Beats",
Function=function(az)
if az then
aw=Instance.new"Sound"
aw.Volume=as.Value/100
aw.Parent=workspace
repeat
if not aw.Playing then
choosesong()
end
if au<tick()and ah.Enabled and aj.Enabled then
au=tick()+ax
av=math.min(
L.FovController:getFOV()*(L.SprintController.sprinting and 1.1 or 1),
120
)
r.FieldOfView=av-ak.Value
ay=j:Create(
r,
TweenInfo.new(math.min(ax,0.2),Enum.EasingStyle.Linear),
{FieldOfView=av}
)
ay:Play()
end
task.wait()
until not ah.Enabled
else
if aw then
aw:Destroy()
end
if ay then
ay:Cancel()
end
if av then
r.FieldOfView=av
end
table.clear(at)
end
end,
Tooltip="Built in mp3 player",
}
ai=ah:CreateTextList{
Name="Songs",
Placeholder="filepath/bpm/start",
}
aj=ah:CreateToggle{
Name="Beat FOV",
Function=function(az)
if ak.Object then
ak.Object.Visible=az
end
if ah.Enabled then
ah:Toggle()
ah:Toggle()
end
end,
Default=true,
}
ak=ah:CreateSlider{
Name="Adjustment",
Min=1,
Max=30,
Default=5,
Darker=true,
}
as=ah:CreateSlider{
Name="Volume",
Function=function(az)
if aw then
aw.Volume=az/100
end
end,
Min=1,
Max=100,
Default=100,
Suffix="%",
}
end)

b(function()
local ah
local ai
local aj={}
local ak

ah=u.Legit:CreateModule{
Name="SoundChanger",
Function=function(as)
if as then
ak=L.SoundManager.playSound
L.SoundManager.playSound=function(at,au,...)
if aj[au]then
au=aj[au]
end

return ak(at,au,...)
end
else
L.SoundManager.playSound=ak
ak=nil
end
end,
Tooltip="Change ingame sounds to custom ones.",
}
ai=ah:CreateTextList{
Name="Sounds",
Placeholder="(DAMAGE_1/ben.mp3)",
Function=function()
table.clear(aj)
for as,at in ai.ListEnabled do
local au=at:split"/"
local av=L.SoundList[au[1] ]
if av and#au>1 then
aj[av]=au[2]:find"rbxasset"and au[2]
or isfile(au[2])and t(au[2])
or""
end
end
end,
}
end)

b(function()
local ah
local ai
local aj
local ak
local as=
getRoactRender(require(s.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-app"]).HotbarApp.render)
local at=
require(s.PlayerScripts.TS.controllers.global.hotbar.ui["hotbar-open-inventory"]).HotbarOpenInventory
local au,av={},{}
local aw

u:Clean(function()
for ax,ay in av do
table.clear(ay)
end
for ax,ay in au do
table.clear(ay)
end
table.clear(av)
table.clear(au)
end)

local function modifyconstant(ax,ay,az)
if not au[ax]then
au[ax]={}
end
if not av[ax]then
av[ax]={}
end
if not au[ax][ay]then
local aA=type(au[ax][ay])
if aA=="function"or aA=="userdata"then
return
end
au[ax][ay]=debug.getconstant(ax,ay)
end
if typeof(au[ax][ay])~=typeof(az)and az~=nil then
return
end

av[ax][ay]=az
if ah.Enabled then
if az then
debug.setconstant(ax,ay,az)
else
debug.setconstant(ax,ay,au[ax][ay])
au[ax][ay]=nil
end
end
end

ah=u.Legit:CreateModule{
Name="UI Cleanup",
Function=function(ax)
for ay,az in(ax and av or au)do
for aA,aB in az do
debug.setconstant(ay,aA,aB)
end
end
if ax then
if ai.Enabled then
O=at.render
at.render=function()
return L.Roact.createElement("TextButton",{Visible=false},{})
end
end

if aj.Enabled then
aw=L.KillFeedController.addToKillFeed
L.KillFeedController.addToKillFeed=function()end
end

if ak.Enabled then
g:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,true)
end
else
if O then
at.render=O
O=nil
end

if aj.Enabled then
L.KillFeedController.addToKillFeed=aw
aw=nil
end

if ak.Enabled then
g:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
end
end
end,
Tooltip="Cleans up the UI for kits & main",
}
ah:CreateToggle{
Name="Resize Health",
Function=function(ax)
modifyconstant(as,60,ax and 1 or nil)
modifyconstant(debug.getupvalue(as,15).render,30,ax and 1 or nil)
modifyconstant(debug.getupvalue(as,23).tweenPosition,16,ax and 0 or nil)
end,
Default=true,
}
ah:CreateToggle{
Name="No Hotbar Numbers",
Function=function(ax)
local ay=O or at.render
modifyconstant(debug.getupvalue(as,23).render,90,ax and 0 or nil)
modifyconstant(ay,71,ax and 0 or nil)
end,
Default=true,
}
ai=ah:CreateToggle{
Name="No Inventory Button",
Function=function(ax)
modifyconstant(as,78,ax and 0 or nil)
if ah.Enabled then
if ax then
O=at.render
at.render=function()
return L.Roact.createElement("TextButton",{Visible=false},{})
end
else
at.render=O
O=nil
end
end
end,
Default=true,
}
aj=ah:CreateToggle{
Name="No Kill Feed",
Function=function(ax)
if ah.Enabled then
if ax then
aw=L.KillFeedController.addToKillFeed
L.KillFeedController.addToKillFeed=function()end
else
L.KillFeedController.addToKillFeed=aw
aw=nil
end
end
end,
Default=true,
}
ak=ah:CreateToggle{
Name="Old Player List",
Function=function(ax)
if ah.Enabled then
g:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,ax)
end
end,
Default=true,
}
ah:CreateToggle{
Name="Fix Queue Card",
Function=function(ax)
modifyconstant(L.QueueCard.render,15,ax and 0.1 or nil)
end,
Default=true,
}
end)

b(function()
local ah={Value=8}
local ai={Value=8}
local aj={Value=-2}
local ak={Value=0}
local as={Value=0}
local at={Value=0}
local au
local av
local aw=u.Categories.Render:CreateModule{
Name="NoBob",
Function=function(aw)
local ax=r:FindFirstChild"Viewmodel"
if ax then
if aw then
av=L.ViewmodelController.playAnimation
L.ViewmodelController.playAnimation=function(ay,az,aA)
if az==L.AnimationType.FP_WALK then
return
end
return av(ay,az,aA)
end
L.ViewmodelController:setHeldItem(
s.Character
and s.Character:FindFirstChild"HandInvItem"
and s.Character.HandInvItem.Value
and s.Character.HandInvItem.Value:Clone()
)
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_DEPTH_OFFSET",
-(ah.Value/10)
)
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_HORIZONTAL_OFFSET",
(ai.Value/10)
)
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_VERTICAL_OFFSET",
(aj.Value/10)
)
au=ax.RightHand.RightWrist.C1
ax.RightHand.RightWrist.C1=au
*CFrame.Angles(math.rad(ak.Value),math.rad(as.Value),math.rad(at.Value))
else
L.ViewmodelController.playAnimation=av
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_DEPTH_OFFSET",
0
)
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_HORIZONTAL_OFFSET",
0
)
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_VERTICAL_OFFSET",
0
)
ax.RightHand.RightWrist.C1=au
end
end
end,
Tooltip="Removes the ugly bobbing when you move and makes sword farther",
}
ah=aw:CreateSlider{
Name="Depth",
Min=0,
Max=24,
Default=8,
Function=function(ax)
if aw.Enabled then
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_DEPTH_OFFSET",
-(ax/10)
)
end
end,
}
ai=aw:CreateSlider{
Name="Horizontal",
Min=0,
Max=24,
Default=8,
Function=function(ax)
if aw.Enabled then
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_HORIZONTAL_OFFSET",
(ax/10)
)
end
end,
}
aj=aw:CreateSlider{
Name="Vertical",
Min=0,
Max=24,
Default=-2,
Function=function(ax)
if aw.Enabled then
s.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute(
"ConstantManager_VERTICAL_OFFSET",
(ax/10)
)
end
end,
}
ak=aw:CreateSlider{
Name="RotX",
Min=0,
Max=360,
Function=function(ax)
if aw.Enabled then
r.Viewmodel.RightHand.RightWrist.C1=au
*CFrame.Angles(math.rad(ak.Value),math.rad(as.Value),math.rad(at.Value))
end
end,
}
as=aw:CreateSlider{
Name="RotY",
Min=0,
Max=360,
Function=function(ax)
if aw.Enabled then
r.Viewmodel.RightHand.RightWrist.C1=au
*CFrame.Angles(math.rad(ak.Value),math.rad(as.Value),math.rad(at.Value))
end
end,
}
at=aw:CreateSlider{
Name="RotZ",
Min=0,
Max=360,
Function=function(ax)
if aw.Enabled then
r.Viewmodel.RightHand.RightWrist.C1=au
*CFrame.Angles(math.rad(ak.Value),math.rad(as.Value),math.rad(at.Value))
end
end,
}
end)

b(function()
local ah
local ai
local aj={}

ah=u.Legit:CreateModule{
Name="WinEffect",
Function=function(ak)
if ak then
ah:Clean(c.MatchEndEvent.Event:Connect(function()
for as,at in getconnections(L.Client:Get"WinEffectTriggered".instance.OnClientEvent)do
if at.Function then
at.Function{
winEffectType=aj[ai.Value],
winningPlayer=s,
}
end
end
end))
end
end,
Tooltip="Allows you to select any clientside win effect",
}
local ak={}
for as,at in L.WinEffectMeta do
table.insert(ak,at.name)
aj[at.name]=as
end
table.sort(ak)
ai=ah:CreateDropdown{
Name="Effects",
List=ak,
}
end)

local function createMonitoredTable(ah,ai)
local aj={}
local ak={
__index=ah,
__newindex=function(ak,as,at)
local au=ah[as]
ah[as]=at
if ai then
ai(as,au,at)
end
end,
}
setmetatable(aj,ak)
return aj
end
local function onChange(ah,ai,aj)
getgenv().GlobalStore=F
shared.GlobalStore=F
end
local function onChange2(ah,ai,aj)
getgenv().GlobalBedwars=L
shared.GlobalBedwars=L
end

F=createMonitoredTable(F,onChange)
L=createMonitoredTable(L,onChange2)

getgenv().GlobalStore=F
shared.GlobalStore=F

getgenv().GlobalBedwars=L
shared.GlobalBedwars=L