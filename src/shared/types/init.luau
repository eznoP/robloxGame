--!strict
-- Types centrais, compartilhados entre server e client.
-- Os tipos específicos de domínio (BiomeConfig, AxeConfig, etc.) entram aqui
-- conforme cada sistema é construído (Fase 1+).

export type Dictionary<V> = { [string]: V }
export type Array<V> = { V }

-- Identificadores. Em Luau estrito, aliases simples são mais úteis que
-- os "branded types" do plano (ver errata).
export type BiomeId = string
export type AxeId = string
export type PetId = string
export type TreeId = string

return {}
