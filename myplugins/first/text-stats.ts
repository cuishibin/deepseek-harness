import type { Context } from '@deepseek-ai/cordis'
import { defineTool } from '@deepseek-ai/dsh-tools'

/** 提供一个只统计输入文本、不读写文件的工具。 */
export const name = 'text-stats'

/** 等待 Cordis 提供工具注册表。 */
export const inject = ['tools']

/**
 * 注册文本统计工具；工具随插件卸载而注销。
 * @param ctx - 已提供工具注册表的插件上下文。
 */
export function apply(ctx: Context): void {
  ctx.tools.register(defineTool({
    name: 'text_stats',
    description: '统计文本的 Unicode 码点数和行数。字符数包含空白和换行；行数保留末尾空行，空文本为零行。',
    parameters: {
      text: { type: 'string', required: true, description: '要统计的原始文本' },
    },
    output: {
      schema: {
        type: 'object',
        properties: {
          characters: { type: 'integer', required: true },
          lines: { type: 'integer', required: true },
        },
        additionalProperties: false,
      },
      render: (_args, value) => [{
        type: 'text', text: `字符数：${value.characters}；行数：${value.lines}`,
      }],
    },
    async execute({ text }) {
      // 字符串迭代按 Unicode 码点计数，不会把一个补充平面字符拆成两个。
      let characters = 0
      for (const _character of text) characters++

      // 优先匹配 CRLF，避免 Windows 换行被算成两次分隔。
      const lines = text === '' ? 0 : text.split(/\r\n|[\r\n]/u).length
      return { characters, lines }
    },
  }))
}
