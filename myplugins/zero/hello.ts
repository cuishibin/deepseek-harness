/** 最小 DSH 插件：用终端日志确认 Cordis 已加载模块。 */
export const name = 'simple-hello'

/** Cordis 加载插件时调用此入口；本示例不依赖其他服务。 */
export function apply(): void {
  console.log('[simple-hello] 插件已加载')
}
