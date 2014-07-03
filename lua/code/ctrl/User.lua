local util = loadMod("core.util")
local exception = loadMod("core.exception")
local request = loadMod("core.request")
local response = loadMod("core.response")
local push = loadMod("core.push")
local ctrlBase = loadMod("core.base.ctrl")
local session = loadMod("core.session")
local consts = loadMod("code.const.user")
local userService = util:getService("user")

--- 用户操作
local User = {}

--- 用户注册
--
-- @param string name 用户名称
-- @param string passwd 用户密码
-- @param number icon 头像ID
-- @param number heroId 英雄ID
-- @error user.errNameLen user.nameForbid user.nameExist
-- @error user.errPwdLen user.invalidIcon
-- @return {"userData":{"user":{"level":1,"loginTime":1404302188,"icon":2,"id":4,"status":0,"lastModify":1404198234,"maxEnergy":120,"loginIp":"61.148.75.238","regTime":1404198234,"passwd":"d0e16bcc1e6afadf7154183c9e78114c683e6563","exp":0,"regIp":"61.148.75.238","gold":9948510,"name":"zivn","lastEnergy":120},"heros":[{"level":1,"att":53,"id":12,"hp":243,"heroId":4,"dodge":5,"price":1220,"exp":0,"crit":20,"hit":95,"userId":4,"def":24},{"level":1,"att":143,"id":4,"hp":394,"heroId":1,"dodge":20,"price":1220,"exp":0,"crit":20,"hit":80,"userId":4,"def":25}],"equips":[{"level":9,"price":7050,"position":1,"id":1,"effects":[{"type":101,"value":140},{"type":100,"value":50}],"heroId":0,"userId":4,"equipId":1},{"level":1,"price":3050,"position":1,"id":2,"effects":[{"type":101,"value":100},{"type":100,"value":50}],"heroId":4,"userId":4,"equipId":1}]},"zoneOffset":0,"serverTime":1404302188,"token":"4e8e395aef51ca64fc34b5e1739a9157","pushVer":1555}
function User:register()
    local name = request:getStrParam("name", true, true)
    local passwd = request:getStrParam("passwd", true)
    local icon = request:getNumParam("icon", true, true)
    local heroId = request:getNumParam("heroId", true, true)

    local nameWidth = util.string:width(name)

    if nameWidth < 4 or nameWidth > 12 then
        exception:raise("user.errNameLen", { name = name })
    end

    local passwdWidth = util.string:width(passwd)

    if passwdWidth < 6 or nameWidth > 12 then
        exception:raise("user.errPwdLen", { name = name })
    end

    if icon < consts.INIT_MIN_ICON or icon > consts.INIT_MAX_ICON then
        exception:raise("user.invalidIcon", { icon = icon })
    end

    if util.string:checkFilter(name) then
        exception:raise("user.nameForbid", { name = name })
    end

    if userService:nameExist(name) then
        exception:raise("user.nameExist", { name = name })
    end

    if not util.table:hasValue(consts.INIT_HEROS, heroId) then
        exception:raise("core.forbidden", { heroId = heroId })
    end

    local user = userService:create(name, passwd, icon, heroId, request:getIp())
    local token = session:register({ userId = user.id, userName = user.name })
    local userData = userService:getUserData(user)

    response:reply({
        token = token,
        serverTime = util:now(),
        zoneOffset = util:getTimeOffset(),
        pushVer = push:getVersion(),
        userData = userData
    }, nil, true)
end

--- 用户登录
--
-- @param string name 用户名称
-- @param string passwd 用户密码
-- @error user.needInit user.wrongPwd user.banLogin
-- @return {"userData":{"user":{"level":1,"loginTime":1404302188,"icon":2,"id":4,"status":0,"lastModify":1404198234,"maxEnergy":120,"loginIp":"61.148.75.238","regTime":1404198234,"passwd":"d0e16bcc1e6afadf7154183c9e78114c683e6563","exp":0,"regIp":"61.148.75.238","gold":9948510,"name":"zivn","lastEnergy":120},"heros":[{"level":1,"att":53,"id":12,"hp":243,"heroId":4,"dodge":5,"price":1220,"exp":0,"crit":20,"hit":95,"userId":4,"def":24},{"level":1,"att":143,"id":4,"hp":394,"heroId":1,"dodge":20,"price":1220,"exp":0,"crit":20,"hit":80,"userId":4,"def":25}],"equips":[{"level":9,"price":7050,"position":1,"id":1,"effects":[{"type":101,"value":140},{"type":100,"value":50}],"heroId":0,"userId":4,"equipId":1},{"level":1,"price":3050,"position":1,"id":2,"effects":[{"type":101,"value":100},{"type":100,"value":50}],"heroId":4,"userId":4,"equipId":1}]},"zoneOffset":0,"serverTime":1404302188,"token":"4e8e395aef51ca64fc34b5e1739a9157","pushVer":1555}
function User:login()
    local name = request:getStrParam("name", true, true)
    local passwd = request:getStrParam("passwd", true)

    local user = userService:getByName(name)

    if not user then
        exception:raise("user.needInit", { name = name })
    end

    if user.passwd ~= userService:mixPwd(passwd) then
        exception:raise("user.wrongPwd", { name = name, passwd = passwd })
    end

    if userService:isBanLogin(user) then
        exception:raise("user.banLogin", { userId = userInfo.userId, userStatus = user.status })
    end

    user.loginTime = util:now()
    user.loginIp = request:getIp()
    userService:update(user, { "loginTime", "loginIp" })

    local token = session:register({ userId = user.id, userName = user.name })
    local userData = userService:getUserData(user)

    response:reply({
        token = token,
        serverTime = util:now(),
        zoneOffset = util:getTimeOffset(),
        pushVer = push:getVersion(),
        userData = userData
    }, nil, true)
end

--- 更换头像
--
-- @param string token 用户验证token
-- @param number icon 头像ID
-- @error user.needInit user.invalidIcon
-- @return {"ok":true}
function User:changeIcon()
    local userInfo = self:getSessionInfo()
    local icon = request:getNumParam("icon", true, true)

    if icon < consts.INIT_MIN_ICON or icon > consts.INIT_MAX_ICON then
        exception:raise("user.invalidIcon", { icon = icon })
    end

    local user = userService:getOne(userInfo.userId)

    if not user then
        exception:raise("user.needInit", { userId = userId })
    end

    if user.icon ~= icon then
        user.icon = icon
        userService:update(user, { "icon" })
    end

    response:reply({ ok = true })
end

return util:inherit(User, ctrlBase)
