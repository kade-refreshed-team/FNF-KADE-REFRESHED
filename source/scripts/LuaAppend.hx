package scripts;

/**
 * Used for prefixes and suffixes for lua scripts.
 */
class LuaAppend {

    /**
     * The suffix for object oriented lua.
     * Used on all lua scripts.
     */
    public static var LUA_SUFFIX = '\nsetmetatable(_G, {
        __call = function(func, ...)
            return func(script.parent, ...);
        end,
        __newindex = function (notUsed, name, value)
            __scriptMetatable.__newindex(script.parent, name, value)
        end,
        __index = function (notUsed, name)
            return __scriptMetatable.__index(script.parent, name)
        end
    })';
}