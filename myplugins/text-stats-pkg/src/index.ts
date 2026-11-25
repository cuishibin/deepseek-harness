import type { Context } from '@deepseek-ai/cordis'
import type { ToolDefinition } from '@deepseek-ai/dsh-tools'

/** 工具的规范返回值结构，与 output.schema 一一对应。 */
interface TextStatsValue {
  characters: number
  lines: number
}

/**
 * 将宽 JsonValue 收窄为规范值；render 无法信任上游已按 schema 校验。
 * @param value - 注册表传入的输出快照。
 * @returns 匹配 TextStatsValue 的同一对象。
 */
/** render 收到的输出快照：JSON 值的并集，schema 声明根为 object。 */
type JsonLikeValue = string | number | boolean | null | object

function asTextStatsValue(value: JsonLikeValue): TextStatsValue {
  // null 分支按缺字段处理为 NaN，由渲染原样呈现。
  const record = (value ?? {}) as Record<string, unknown>
  return { characters: Number(record.characters), lines: Number(record.lines) }
}

/**
 * 本插件的工具定义；不经过 defineTool 包装，因此参数校验自行负责。
 */
const textStatsTool: ToolDefinition = {
  name: 'text_stats',
  description: '统计文本的 Unicode 码点数和行数。字符数包含空白和换行；行数保留末尾空行，空文本为零行。',
  parameters: {
    type: 'object',
    properties: {
      text: { type: 'string', description: '要统计的原始文本' },
    },
    required: ['text'],
  },
  output: {
    schema: {
      type: 'object',
      properties: {
        characters: { type: 'integer' },
        lines: { type: 'integer' },
      },
      required: ['characters', 'lines'],
    },
    // 原生定义的 value 是宽 JsonValue；按 schema 收窄后渲染。
    render: (_args, value) => [{
      type: 'text',
      text: `字符数：${asTextStatsValue(value).characters}；行数：${asTextStatsValue(value).lines}`,
    }],
  },
  /**
   * 执行统计并返回规范值。
   * @param args - 模型生成的参数（已冻结的快照）。
   * @returns 符合 output.schema 的规范值。
   * @throws TypeError 当模型传入的 text 不是字符串时。
   */
  async execute(args) {
    // 未经 defineTool 校验，工具自行把关参数类型。
    const text = (args as { text?: unknown }).text
    if (typeof text !== 'string') {
      throw new TypeError('text_stats: "text" must be a string')
    }

    // 字符串迭代按 Unicode 码点计数，不会把一个补充平面字符拆成两个。
    let characters = 0
    for (const _character of text) characters++

    // 优先匹配 CRLF，避免 Windows 换行被算成两次分隔。
    const lines = text === '' ? 0 : text.split(/\r\n|[\r\n]/u).length
    return { characters, lines }
  },
}

/** 提供一个只统计输入文本、不读写文件的工具。 */
export const name = 'text-stats'

/** 等待 Cordis 提供工具注册表。 */
export const inject = ['tools']

/**
 * 插件入口：注册文本统计工具；工具随插件卸载而注销。
 * @param ctx - 已提供工具注册表的插件上下文。
 */
export function apply(ctx: Context): void {
  ctx.tools.register(textStatsTool)
}
