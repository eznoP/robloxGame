--!strict
--!optimize 2
-- EventBus: pub/sub tipado e sem dependências.
-- Cada callback roda em sua própria thread (task.spawn), então um erro em um
-- listener não derruba os outros.

local EventBus = {}
EventBus.__index = EventBus

export type Listener = (...any) -> ()
export type Connection = { Disconnect: (self: Connection) -> () }
export type EventBus = typeof(setmetatable(
	{} :: {
		_listeners: { [string]: { Listener } },
	},
	EventBus
))

function EventBus.new(): EventBus
	return setmetatable({ _listeners = {} }, EventBus)
end

function EventBus.on(self: EventBus, event: string, callback: Listener): Connection
	local list = self._listeners[event]
	if not list then
		list = {}
		self._listeners[event] = list
	end
	table.insert(list, callback)

	return {
		Disconnect = function(_)
			local current = self._listeners[event]
			if not current then
				return
			end
			local index = table.find(current, callback)
			if index then
				table.remove(current, index)
			end
		end,
	}
end

function EventBus.emit(self: EventBus, event: string, ...: any)
	local list = self._listeners[event]
	if not list then
		return
	end
	-- clona para que um Disconnect dentro de um listener não altere a iteração
	for _, callback in ipairs(table.clone(list)) do
		task.spawn(callback, ...)
	end
end

return EventBus
