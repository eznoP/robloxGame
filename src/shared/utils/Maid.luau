--!strict
--!optimize 2
-- Maid: guarda coisas que precisam ser limpas e limpa todas de uma vez.
-- Aceita RBXScriptConnection, Instance, função, ou tabela com :Destroy/:Disconnect.
-- Substitui a dependência Wally "Maid" com uma implementação própria (ver errata).

local Maid = {}
Maid.__index = Maid

export type Task =
	RBXScriptConnection
	| Instance
	| () -> ()
	| { Destroy: (any) -> () }
	| { Disconnect: (any) -> () }

export type Maid = typeof(setmetatable(
	{} :: {
		_tasks: { Task },
	},
	Maid
))

function Maid.new(): Maid
	return setmetatable({ _tasks = {} }, Maid)
end

-- Registra um item e o devolve, para encadear: local part = maid:give(Instance.new("Part"))
function Maid.give(self: Maid, item: Task): Task
	table.insert(self._tasks, item)
	return item
end

local function cleanupOne(item: any)
	if typeof(item) == "RBXScriptConnection" then
		item:Disconnect()
	elseif typeof(item) == "Instance" then
		item:Destroy()
	elseif type(item) == "function" then
		item()
	elseif type(item) == "table" then
		if type(item.Destroy) == "function" then
			item:Destroy()
		elseif type(item.Disconnect) == "function" then
			item:Disconnect()
		end
	end
end

-- Limpa tudo, na ordem inversa de inserção (LIFO).
function Maid.clean(self: Maid)
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		cleanupOne(tasks[i])
	end
end

Maid.Destroy = Maid.clean

return Maid
