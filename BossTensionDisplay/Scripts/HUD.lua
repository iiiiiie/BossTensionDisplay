local Reader = require('Reader')
local HUD = {}
HUD.__index = HUD
local valid = Reader.valid
local classes = {
    user = '/Script/UMG.UserWidget', tree = '/Script/UMG.WidgetTree',
    canvas = '/Script/UMG.CanvasPanel', border = '/Script/UMG.Border', text = '/Script/UMG.TextBlock',
}
local ink = { R = 0.88, G = 0.85, B = 0.75, A = 1 }
local muted = { R = 0.48, G = 0.53, B = 0.54, A = 1 }
local colors = {
    { R=0.26, G=0.64, B=0.72, A=1 }, { R=0.40, G=0.65, B=0.60, A=1 },
    { R=0.77, G=0.76, B=0.59, A=1 }, { R=0.92, G=0.69, B=0.28, A=1 },
    { R=0.95, G=0.39, B=0.20, A=1 }, { R=0.94, G=0.18, B=0.18, A=1 },
}
local tiers = {'冷静', '稳健', '平常', '吃紧', '慌乱', '崩溃'}
local dimensions = {
    {'Dim.Defense','防御'}, {'Dim.Offense','进攻'}, {'Dim.Dodge','闪避'},
    {'Dim.Rhythm','节奏'}, {'Dim.Health','血量'}, {'Dim.Posture','杀气'}, {'Dim.Resource','资源'},
}
local outcomes = {
    ['Outcome.Defense.PerfectDeflect']='完美格挡',
    ['Outcome.Defense.PerfectDeflect.PowerAttack']='重击完美格挡',
    ['Outcome.Defense.NormalBlock']='普通格挡', ['Outcome.Defense.GuardBreak']='被破防',
    ['Outcome.Defense.GuardBreak.Normal']='被破防', ['Outcome.Defense.GuardBreak.Executed']='破防后被处决',
    ['Outcome.Defense.HitWhileBlocking']='格挡时受击', ['Outcome.Defense.NoResponseHit']='没反应就挨打',
    ['Outcome.Defense.Grabbed']='被投技命中', ['Outcome.Defense.RedEyeHit']='红眼招式命中',
    ['Outcome.Dodge.PerfectDodge']='完美闪避', ['Outcome.Dodge.DodgeSuccess']='闪避成功',
    ['Outcome.Dodge.GrazeDodge']='擦身闪避', ['Outcome.Dodge.PerfectDodge.Forced']='完美闪避',
    ['Outcome.Dodge.PerfectDodge.Optional']='完美闪避', ['Outcome.Offense.HitLanded']='打中',
    ['Outcome.Offense.WhiffedAttack']='攻击落空', ['Outcome.Offense.GreedyHit']='贪刀受击',
    ['Outcome.Offense.BreakCaused']='造成破防', ['Outcome.Offense.ExecutedBoss']='处决首领',
    ['Outcome.Offense.HeavyHit']='重击命中', ['Outcome.Offense.WeaponSwitchHit']='切武器命中',
    ['Outcome.Offense.BreakWindowHit']='破防追击', ['Outcome.Session.PlayerKilled']='玩家倒下',
    ['Outcome.Session.BossKilled']='击败首领', ['Outcome.Hidden.Whiffed']='攻击落空',
    ['Outcome.Hidden.PreemptiveBlock']='提前格挡', ['Outcome.Player.Mistake.AbilityNoResource']='资源不足',
    ['Outcome.Player.Mistake.HealNoConsumable']='药品不足',
}
local function color(widget, value)
    widget:SetColorAndOpacity({ SpecifiedColor = value, ColorUseRule = 0 })
end
local function setText(widget, value)
    widget:SetText(FText(value))
end
local function add(parent, widget, x, y, width, height)
    local slot = parent:AddChildToCanvas(widget)
    slot:SetAnchors({Minimum={X=0,Y=0},Maximum={X=0,Y=0}})
    slot:SetAlignment({X=0,Y=0})
    slot:SetPosition({X=x,Y=y})
    slot:SetSize({X=width,Y=height})
    slot:SetAutoSize(false)
    return slot
end
local function clamp(n, low, high) return math.max(low, math.min(high, n)) end
function HUD.new(settings)
    return setmetatable({ settings = settings }, HUD)
end
function HUD:destroy()
    if valid(self.root) then pcall(function() self.root:RemoveFromParent() end) end
    -- __DEPRECATED_20261107__ Game-instance-only ownership missed world transitions.
    -- self.root, self.tree, self.canvas, self.owner = nil, nil, nil, nil
    self.root, self.tree, self.canvas, self.owner, self.world = nil, nil, nil, nil, nil
    self.ownerAddress, self.worldAddress=nil,nil
end
function HUD:construct(kind, outer)
    -- __DEPRECATED_20261107__ Untracked descendants could outlive their native widgets during travel.
    -- return StaticConstructObject(StaticFindObject(classes[kind]), outer)
    local widget=StaticConstructObject(StaticFindObject(classes[kind]), outer)
    self.references=self.references or {}
    self.references[#self.references+1]=widget
    return widget
end
function HUD:allValid()
    if not valid(self.root) then return false end
    for _, object in ipairs(self.references or {}) do
        if not valid(object) then return false end
    end
    return true
end
function HUD:box(x, y, width, height, value)
    local widget = self:construct('border', self.tree)
    widget:SetPadding({Left=0,Top=0,Right=0,Bottom=0})
    widget:SetBrushColor(value)
    widget:SetVisibility(3)
    return widget, add(self.canvas, widget, x, y, width, height)
end
function HUD:label(x, y, width, height, size, value, tint)
    local widget = self:construct('text', self.tree)
    widget.Font.Size = size
    setText(widget, value or '')
    color(widget, tint or ink)
    widget:SetVisibility(3)
    add(self.canvas, widget, x, y, width, height)
    return widget
end
function HUD:build(context)
    self:destroy()
    self.references={}
    self.root = self:construct('user', context.gameInstance)
    self.tree = self:construct('tree', self.root)
    self.root.WidgetTree = self.tree
    local rootCanvas = self:construct('canvas', self.tree)
    self.tree.RootWidget = rootCanvas
    self.canvas = self:construct('canvas', self.tree)
    local slot = add(rootCanvas, self.canvas, -self.settings.RightMargin, self.settings.TopMargin, 330, 466)
    slot:SetAnchors({Minimum={X=1,Y=0},Maximum={X=1,Y=0}})
    slot:SetAlignment({X=1,Y=0})
    self.canvas:SetRenderTransformPivot({X=1,Y=0})
    self.canvas:SetRenderScale({X=self.settings.Scale,Y=self.settings.Scale})
    self:box(0,0,330,466,{R=0.018,G=0.025,B=0.026,A=0.84})
    self:box(0,0,3,466,{R=0.65,G=0.47,B=0.23,A=0.85})
    self.title = self:label(14,10,130,41,27,'压力显示')
    self.raw = self:label(147,8,171,46,31,'--')
    self.raw:SetJustification(2)
    self.detail = self:label(15,56,304,21,12,'等待首领战',muted)
    local bounds = {-100,-40,-10,10,40,75,100}
    for i=1,6 do
        self:box(15+(bounds[i]+100)*1.5,84,(bounds[i+1]-bounds[i])*1.5,6,colors[i])
    end
    self.marker, self.markerSlot = self:box(164,80,2,14,ink)
    self:label(15,94,302,17,9,'-100       -40    -10  0   10    40     75  100',muted)
    self.rows = {}
    for i, dimension in ipairs(dimensions) do
        local y=118+(i-1)*22
        self:label(15,y,48,21,13,dimension[2],muted)
        self:box(75,y+8,176,4,{R=0.09,G=0.11,B=0.11,A=1})
        self:box(163,y+4,1,12,muted)
        local bar, barSlot=self:box(163,y+7,1,6,colors[1])
        local value=self:label(256,y-1,59,22,14,'--')
        value:SetJustification(2)
        self.rows[i]={key=dimension[1],bar=bar,slot=barSlot,text=value,y=y}
    end
    self.player = self:label(15,276,301,20,12,'血量 --  杀气 --  药 --',muted)
    self:box(15,303,300,1,{R=0.16,G=0.18,B=0.18,A=1})
    self:label(15,310,300,18,11,'最近事件                      基础权重',muted)
    self.events={}
    for i=1,6 do
        local y=334+(i-1)*18
        self.events[i]={ weight=self:label(15,y,49,19,12,''),
            name=self:label(68,y,165,19,12,''), base=self:label(238,y,77,19,11,'',muted) }
        self.events[i].base:SetJustification(2)
    end
    self:label(15,447,303,15,9,self.settings.ToggleKey..' 显示/隐藏 · '..self.settings.ReloadKey..' 重新加载',muted)
    self.root:SetVisibility(3)
    self.root:AddToViewport(70)
    -- __DEPRECATED_20261107__ self.owner=context.gameInstance; self.world=context.world
    self.ownerAddress=context.gameInstance:GetAddress()
    self.worldAddress=context.world:GetAddress()
end
function HUD:update(context, sample, reason, visible)
    -- __DEPRECATED_20261107__ if not valid(self.root) or self.owner ~= context.gameInstance then self:build(context) end
    -- __DEPRECATED_20261107__ Root validation alone did not protect descendant SetVisibility calls.
    -- if not valid(self.root) or self.owner ~= context.gameInstance or self.world ~= context.world then self:build(context) end
    -- __DEPRECATED_20261107__ if not self:allValid() or self.owner ~= context.gameInstance or self.world ~= context.world then self:build(context) end
    if not self:allValid() or self.ownerAddress ~= context.gameInstance:GetAddress()
        or self.worldAddress ~= context.world:GetAddress() then self:build(context) end
    if not visible or (not sample and not self.settings.ShowWhenInactive) then
        self.root:SetVisibility(1)
        return
    end
    self.root:SetVisibility(3)
    if sample then
        local index=clamp(math.floor(sample.tier or 2)+1,1,6)
        setText(self.title,tiers[index])
        color(self.title,colors[index])
        setText(self.raw,string.format('%+.1f',sample.raw))
        color(self.raw,colors[index])
        setText(self.detail,string.format('变化 %+.1f /秒   可信度 %.0f%%   首领 %d',sample.delta or 0,(sample.confidence or 0)*100,sample.bossCount or 1))
        self.markerSlot:SetPosition({X=15+(clamp(sample.raw,-100,100)+100)*1.5,Y=80})
        self.marker:SetVisibility(3)
        setText(self.player,string.format('血量 %.0f%%   杀气 %.0f%%   药 %d',(sample.hp or 0)*100,(sample.posture or 0)*100,sample.medicine or 0))
    else
        setText(self.title,'压力显示'); color(self.title,ink)
        setText(self.raw,'--'); color(self.raw,muted)
        setText(self.detail,reason or '等待首领战')
        self.marker:SetVisibility(1)
        setText(self.player,'进入首领战后显示真实读数')
    end
    for _, row in ipairs(self.rows) do
        local value=sample and sample.dimensions[row.key] or nil
        setText(row.text,value and string.format('%+.1f',value) or '--')
        local width=value and math.abs(clamp(value,-50,50))/50*88 or 0
        row.slot:SetPosition({X=value and value<0 and 163-width or 163,Y=row.y+7})
        row.slot:SetSize({X=math.max(0.01,width),Y=6})
        row.bar:SetBrushColor(value and value>0 and colors[5] or colors[1])
        color(row.text,value and value>0 and colors[5] or ink)
    end
    for i, row in ipairs(self.events) do
        local event=sample and i<=self.settings.MaxEvents and sample.events[i] or nil
        -- __DEPRECATED_20261107__ setText(row.weight,event and event.weight and string.format('%+.0f',event.weight) or '')
        setText(row.weight,event and (event.positive and '+' or '−') or '')
        setText(row.name,event and (outcomes[event.tag] or event.tag:match('([^.]+)$') or event.tag) or '')
        setText(row.base,event and event.base and string.format('%+.0f',event.base) or '')
        -- __DEPRECATED_20261107__ color(row.weight,event and event.weight and event.weight>0 and colors[5] or colors[1])
        color(row.weight,event and event.positive and colors[5] or colors[1])
    end
end
return HUD
