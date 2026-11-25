flowchart TB
    User["用户 / 外部调用方"]

    subgraph Entry["应用入口"]
        CLI["dsh CLI<br/>选择并启动 profile"]
        Web["Web UI"]
        Desktop["Desktop<br/>Electron + Host"]
        SDK["SDK / ACP"]
    end

    User --> Web
    User --> Desktop
    User --> SDK
    CLI --> Profile

    subgraph Composition["Profile 与插件组合"]
        Profile["Profile<br/>web / headless / sdk / acp"]
        Bundles["有序组合包<br/>如 dsh-base"]
        Patches["配置叠加<br/>profile patch → home patch → --patch"]
        Cordis["Cordis 插件运行时<br/>共享 ctx · 类型化事件 · 可撤销副作用"]
        Profile --> Bundles --> Patches --> Cordis
    end

    Web --> Profile
    Desktop --> Profile
    SDK --> Profile

    subgraph Core["Agent 核心（packages/core）"]
        Agent["Agent API<br/>ctx.agents"]
        Loop["Agent Loop<br/>ctx.agentLoop"]
        Prompt["系统提示词组装<br/>ctx.systemPrompt"]
        Tools["工具注册与执行流水线<br/>ctx.tools"]
        LLM["LLM 服务与提供方<br/>ctx.llm"]
        Session["Session 事件日志<br/>ctx.sessions"]
    end

    Cordis --> Agent
    Cordis --> Loop
    Cordis --> Prompt
    Cordis --> Tools
    Cordis --> LLM
    Cordis --> Session

    Agent --> Loop
    Loop --> Prompt
    Prompt -->|提示词 + 工具 schema| LLM
    LLM -->|流式响应 / 工具调用| Loop
    Loop --> Tools
    Tools -->|工具结果| Loop
    Loop -->|追加轮次、消息、工具事件| Session

    subgraph Capabilities["可替换能力插件"]
        ModelProviders["模型提供方"]
        ToolPlugins["面向模型的工具<br/>Web · 文件 · Shell · MCP · 等"]
        ExecProviders["执行能力提供方<br/>文件系统 · 子进程 · 终端 · 沙箱"]
        Human["人机协作<br/>审批 · 反馈 · 交互"]
    end

    ModelProviders -.注册到.-> LLM
    ToolPlugins -.注册到.-> Tools
    ExecProviders -.供工具消费.-> ToolPlugins
    Human -.策略 / 生命周期扩展.-> Cordis

    Session --> Persistence["Session 持久化与投影"]
    Session -->|session/event| Client["Client / SDK<br/>订阅事件并呈现对话"]
    Web --> Client
    Desktop --> Client