--!strict
--!optimize 2
-- ObjectPool: reaproveita objetos caros (Parts, ParticleEmitters, Tabelas) para
-- evitar alocações e pressão no GC. Use em projéteis, VFX, NPCs e listas de UI.
-- O método de devolução chama-se `release` ("return" é palavra reservada — ver errata).

local ObjectPool = {}
ObjectPool.__index = ObjectPool

export type Pool<T> = typeof(setmetatable(
	{} :: {
		_available: { T },
		_factory: () -> T,
		_reset: (T) -> (),
	},
	ObjectPool
))

function ObjectPool.new<T>(factory: () -> T, reset: (T) -> ()): Pool<T>
	return setmetatable({
		_available = {},
		_factory = factory,
		_reset = reset,
	}, ObjectPool)
end

function ObjectPool.get<T>(self: Pool<T>): T
	local obj = table.remove(self._available)
	if obj == nil then
		obj = self._factory()
	end
	return (obj :: any) :: T
end

function ObjectPool.release<T>(self: Pool<T>, obj: T)
	self._reset(obj)
	table.insert(self._available, obj)
end

function ObjectPool.prewarm<T>(self: Pool<T>, count: number)
	for _ = 1, count do
		table.insert(self._available, self._factory())
	end
end

return ObjectPool
