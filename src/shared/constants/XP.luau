--!strict
-- Curva de progressão (plano §4.5). O XP total para alcançar um nível segue
-- (level-1)^2 * BASE, então nível 1 começa em 0. Revisado na Fase 7.

local XP = {}

local BASE = 100

-- XP acumulado necessário para ESTAR no início de `level`.
function XP.totalForLevel(level: number): number
	if level <= 1 then
		return 0
	end
	return (level - 1) ^ 2 * BASE
end

-- XP necessário para ir de `level` até `level + 1`.
function XP.forNextLevel(level: number): number
	return XP.totalForLevel(level + 1) - XP.totalForLevel(level)
end

-- Nível correspondente a um XP acumulado.
function XP.levelFromTotal(total: number): number
	if total <= 0 then
		return 1
	end
	return math.floor(math.sqrt(total / BASE)) + 1
end

-- Progresso dentro do nível atual: (xp no nível, xp necessário para o próximo).
function XP.progress(total: number): (number, number)
	local level = XP.levelFromTotal(total)
	local into = total - XP.totalForLevel(level)
	return into, XP.forNextLevel(level)
end

return XP
