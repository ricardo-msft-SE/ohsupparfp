const scenes = [
  {
    title: "Incident reported",
    status: "Awaiting incident brief",
    fleetBadge: "Standby",
    orchestratorCopy: "Monitoring statewide traffic and incident feeds, ready to coordinate the specialist response team.",
    copilot: {
      messages: [
        {
          role: "user",
          text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?"
        }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 0,
      tasksRunning: 0,
      toolCalls: 0,
      sourcesQueried: 0,
      systemsConnected: 0,
      findingsGenerated: 0
    },
    agents: [
      { name: "Incident Agent", status: "Idle", task: "Awaiting task", confidence: "--", progress: 0, lastUpdate: "Standing by" },
      { name: "Traffic Operations Agent", status: "Idle", task: "Awaiting task", confidence: "--", progress: 0, lastUpdate: "Standing by" },
      { name: "Construction Agent", status: "Idle", task: "Awaiting task", confidence: "--", progress: 0, lastUpdate: "Standing by" },
      { name: "Public Communications Agent", status: "Idle", task: "Awaiting task", confidence: "--", progress: 0, lastUpdate: "Standing by" },
      { name: "Transit Coordination Agent", status: "Idle", task: "Awaiting task", confidence: "--", progress: 0, lastUpdate: "Standing by" },
      { name: "Economic Impact Agent", status: "Idle", task: "Awaiting task", confidence: "--", progress: 0, lastUpdate: "Standing by" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Awaiting task", confidence: "--", progress: 0, lastUpdate: "Standing by" }
    ],
    timeline: [
      { time: "16:12:00", text: "Tanker rollover reported on I-70 eastbound" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Fleet activation",
    status: "Fleet activating",
    fleetBadge: "Powering on",
    orchestratorCopy: "Understanding the incident and preparing the specialist response team for coordinated action.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 7,
      toolCalls: 3,
      sourcesQueried: 14,
      systemsConnected: 2,
      findingsGenerated: 0
    },
    agents: [
      { name: "Incident Agent", status: "Receiving Task", task: "Powering on", confidence: "--", progress: 14, lastUpdate: "Ready" },
      { name: "Traffic Operations Agent", status: "Receiving Task", task: "Powering on", confidence: "--", progress: 11, lastUpdate: "Ready" },
      { name: "Construction Agent", status: "Receiving Task", task: "Powering on", confidence: "--", progress: 9, lastUpdate: "Ready" },
      { name: "Public Communications Agent", status: "Receiving Task", task: "Powering on", confidence: "--", progress: 8, lastUpdate: "Ready" },
      { name: "Transit Coordination Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Economic Impact Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" }
    ],
    timeline: [
      { time: "16:12:02", text: "Copilot identified incident brief" },
      { time: "16:12:04", text: "Fleet activation initiated" },
      { time: "16:12:06", text: "Agent cards powered on" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Gathering incident context",
    status: "Gathering 911/CAD and traffic alerts",
    fleetBadge: "Context gathering",
    orchestratorCopy: "Pulling 911/CAD records, traffic management alerts, and live sensor data to assess the scene.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Gathering 911/CAD records and traffic management alerts.", citations: ["911 Dispatch", "CAD System", "Traffic Cameras", "Sensor Network"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 9,
      toolCalls: 7,
      sourcesQueried: 58,
      systemsConnected: 4,
      findingsGenerated: 0
    },
    agents: [
      { name: "Incident Agent", status: "Planning", task: "Pulling 911/CAD alerts", confidence: "74%", progress: 28, lastUpdate: "Reviewing dispatch log" },
      { name: "Traffic Operations Agent", status: "Planning", task: "Reviewing congestion sensors", confidence: "69%", progress: 22, lastUpdate: "Checking camera feeds" },
      { name: "Construction Agent", status: "Planning", task: "Scanning nearby work zones", confidence: "66%", progress: 19, lastUpdate: "Reviewing permits" },
      { name: "Public Communications Agent", status: "Planning", task: "Preparing alert channels", confidence: "63%", progress: 16, lastUpdate: "Reviewing templates" },
      { name: "Transit Coordination Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Economic Impact Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" }
    ],
    timeline: [
      { time: "16:12:08", text: "911/CAD feed connected" },
      { time: "16:12:10", text: "Traffic camera feeds indexed" },
      { time: "16:12:12", text: "Sensor network data synchronized" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Scene details confirmed",
    status: "Correlating scene and hazard data",
    fleetBadge: "Signals found",
    orchestratorCopy: "Evidence is converging from dispatch records, traffic sensors, and hazmat protocols.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Incident confirmed: tanker rollover on I-70 EB near mile marker 112, all lanes blocked, hazmat response underway.", citations: ["911 Dispatch", "State Highway Patrol", "Hazmat Unit"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 11,
      toolCalls: 11,
      sourcesQueried: 142,
      systemsConnected: 6,
      findingsGenerated: 1
    },
    agents: [
      { name: "Incident Agent", status: "Thinking", task: "Confirming scene details", confidence: "84%", progress: 42, lastUpdate: "All lanes blocked confirmed" },
      { name: "Traffic Operations Agent", status: "Thinking", task: "Modeling congestion spread", confidence: "76%", progress: 34, lastUpdate: "Backup exceeds 6 miles" },
      { name: "Construction Agent", status: "Planning", task: "Scanning nearby work zones", confidence: "70%", progress: 27, lastUpdate: "Reviewing active permits" },
      { name: "Public Communications Agent", status: "Planning", task: "Preparing alert channels", confidence: "68%", progress: 24, lastUpdate: "Drafting initial alert" },
      { name: "Transit Coordination Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Economic Impact Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" }
    ],
    timeline: [
      { time: "16:12:14", text: "Hazmat response confirmed on scene" },
      { time: "16:12:16", text: "All lanes eastbound confirmed blocked" },
      { time: "16:12:18", text: "State Highway Patrol situation report received" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Delegating specialist work",
    status: "Assigning specialist tasks",
    fleetBadge: "Agents assigned",
    orchestratorCopy: "Delegating traffic, construction, communications, and downstream impact questions to the right expert agents.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Delegating work to specialist agents.", citations: ["Traffic Operations Agent", "Construction Agent", "Public Communications Agent", "Transit Coordination Agent"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 13,
      toolCalls: 14,
      sourcesQueried: 210,
      systemsConnected: 7,
      findingsGenerated: 2
    },
    agents: [
      { name: "Incident Agent", status: "Receiving Task", task: "Confirming scene details", confidence: "84%", progress: 46, lastUpdate: "Monitoring live updates" },
      { name: "Traffic Operations Agent", status: "Receiving Task", task: "Calculating congestion impact", confidence: "77%", progress: 40, lastUpdate: "Modeling detour options" },
      { name: "Construction Agent", status: "Receiving Task", task: "Checking nearby work zones", confidence: "71%", progress: 33, lastUpdate: "Cross-referencing schedules" },
      { name: "Public Communications Agent", status: "Receiving Task", task: "Preparing public alert", confidence: "70%", progress: 30, lastUpdate: "Drafting messaging" },
      { name: "Transit Coordination Agent", status: "Receiving Task", task: "Assessing transit impact", confidence: "--", progress: 12, lastUpdate: "Reviewing routes" },
      { name: "Economic Impact Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" }
    ],
    timeline: [
      { time: "16:12:20", text: "Copilot assigned Traffic Operations Agent" },
      { time: "16:12:21", text: "Construction Agent activated" },
      { time: "16:12:22", text: "Public Communications Agent activated" },
      { time: "16:12:23", text: "Transit Coordination Agent activated" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Traffic impact analysis",
    status: "Traffic Operations Agent calculating congestion impact",
    fleetBadge: "Congestion review",
    orchestratorCopy: "Traffic Operations Agent is modeling congestion spread and identifying viable detour routes.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Traffic Operations Agent is calculating congestion impact and recommending detours.", citations: ["Traffic Sensors", "Statewide Traffic Management System", "Navigation Data Feed"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 14,
      toolCalls: 17,
      sourcesQueried: 265,
      systemsConnected: 7,
      findingsGenerated: 3
    },
    agents: [
      { name: "Incident Agent", status: "Receiving Task", task: "Monitoring live updates", confidence: "84%", progress: 48, lastUpdate: "Scene stable, hazmat active" },
      { name: "Traffic Operations Agent", status: "Analyzing", task: "Calculating congestion impact", confidence: "86%", progress: 62, lastUpdate: "Detour routes identified" },
      { name: "Construction Agent", status: "Receiving Task", task: "Checking nearby work zones", confidence: "72%", progress: 38, lastUpdate: "Cross-referencing schedules" },
      { name: "Public Communications Agent", status: "Receiving Task", task: "Preparing public alert", confidence: "71%", progress: 34, lastUpdate: "Drafting messaging" },
      { name: "Transit Coordination Agent", status: "Receiving Task", task: "Assessing transit impact", confidence: "68%", progress: 22, lastUpdate: "Reviewing routes" },
      { name: "Economic Impact Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" }
    ],
    timeline: [
      { time: "16:12:25", text: "Statewide Traffic Management System queried" },
      { time: "16:12:27", text: "Congestion spread modeled at 6+ miles" },
      { time: "16:12:29", text: "Detour routes via SR-40 and US-42 identified" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Work zone conflict check",
    status: "Construction Agent checking nearby work zones",
    fleetBadge: "Work zone review",
    orchestratorCopy: "Construction Agent is identifying active work zones near the incident that could worsen traffic conditions.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Construction Agent is identifying nearby work zones that could worsen traffic.", citations: ["Work Zone Database", "Lane Closure System", "District 6 Construction Schedule"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 15,
      toolCalls: 20,
      sourcesQueried: 320,
      systemsConnected: 8,
      findingsGenerated: 4
    },
    agents: [
      { name: "Incident Agent", status: "Receiving Task", task: "Monitoring live updates", confidence: "84%", progress: 50, lastUpdate: "Scene stable, hazmat active" },
      { name: "Traffic Operations Agent", status: "Analyzing", task: "Calculating congestion impact", confidence: "88%", progress: 68, lastUpdate: "Detour routes finalized" },
      { name: "Construction Agent", status: "Analyzing", task: "Checking nearby work zones", confidence: "85%", progress: 64, lastUpdate: "Conflict found near SR-40" },
      { name: "Public Communications Agent", status: "Receiving Task", task: "Preparing public alert", confidence: "72%", progress: 38, lastUpdate: "Drafting messaging" },
      { name: "Transit Coordination Agent", status: "Receiving Task", task: "Assessing transit impact", confidence: "70%", progress: 28, lastUpdate: "Reviewing routes" },
      { name: "Economic Impact Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" }
    ],
    timeline: [
      { time: "16:12:31", text: "Work zone database queried" },
      { time: "16:12:33", text: "Active lane closure found on SR-40 detour route" },
      { time: "16:12:35", text: "Construction conflict flagged to Traffic Operations" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Public communications drafted",
    status: "Public Communications Agent drafting alerts",
    fleetBadge: "Messaging drafted",
    orchestratorCopy: "Public Communications Agent is drafting social media posts, website alerts, and media statements for public release.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Public Communications Agent is drafting social media posts, website alerts, and media statements.", citations: ["Social Media Platform", "ODOT Traveler Website", "Media Distribution List"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 16,
      toolCalls: 22,
      sourcesQueried: 372,
      systemsConnected: 8,
      findingsGenerated: 5
    },
    agents: [
      { name: "Incident Agent", status: "Receiving Task", task: "Monitoring live updates", confidence: "84%", progress: 52, lastUpdate: "Scene stable, hazmat active" },
      { name: "Traffic Operations Agent", status: "Analyzing", task: "Calculating congestion impact", confidence: "88%", progress: 70, lastUpdate: "Detour routes finalized" },
      { name: "Construction Agent", status: "Analyzing", task: "Checking nearby work zones", confidence: "85%", progress: 66, lastUpdate: "Conflict found near SR-40" },
      { name: "Public Communications Agent", status: "Analyzing", task: "Drafting public alert", confidence: "89%", progress: 70, lastUpdate: "Draft ready for review" },
      { name: "Transit Coordination Agent", status: "Receiving Task", task: "Assessing transit impact", confidence: "72%", progress: 32, lastUpdate: "Reviewing routes" },
      { name: "Economic Impact Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" }
    ],
    timeline: [
      { time: "16:12:37", text: "Social media alert drafted" },
      { time: "16:12:39", text: "ODOT traveler website alert prepared" },
      { time: "16:12:41", text: "Media statement drafted for distribution" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Cross-agent collaboration",
    status: "Agents are collaborating and correlating findings",
    fleetBadge: "Collaboration live",
    orchestratorCopy: "The specialist agents are correlating evidence, bridging traffic, construction, transit, and communications into one operating picture.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Agents are collaborating and correlating findings.", citations: ["Detour Alignment", "Transit Rerouting", "Public Messaging Sync"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 17,
      toolCalls: 24,
      sourcesQueried: 430,
      systemsConnected: 9,
      findingsGenerated: 6
    },
    agents: [
      { name: "Incident Agent", status: "Collaborating", task: "Sharing scene updates", confidence: "86%", progress: 60, lastUpdate: "Coordinating with Traffic Ops" },
      { name: "Traffic Operations Agent", status: "Collaborating", task: "Aligning detour with work zones", confidence: "90%", progress: 78, lastUpdate: "Revised detour avoids SR-40" },
      { name: "Construction Agent", status: "Collaborating", task: "Confirming detour clearance", confidence: "87%", progress: 74, lastUpdate: "Alternate route confirmed clear" },
      { name: "Public Communications Agent", status: "Collaborating", task: "Syncing detour messaging", confidence: "90%", progress: 76, lastUpdate: "Messaging aligned with new detour" },
      { name: "Transit Coordination Agent", status: "Collaborating", task: "Rerouting affected transit lines", confidence: "82%", progress: 58, lastUpdate: "Three routes rerouted" },
      { name: "Economic Impact Agent", status: "Receiving Task", task: "Estimating delay costs", confidence: "--", progress: 14, lastUpdate: "Beginning analysis" },
      { name: "Executive Briefing Agent", status: "Idle", task: "Standby", confidence: "--", progress: 0, lastUpdate: "Waiting" }
    ],
    timeline: [
      { time: "16:12:43", text: "Traffic Operations and Construction aligned on detour route" },
      { time: "16:12:45", text: "Transit Coordination rerouted affected bus lines" },
      { time: "16:12:47", text: "Public messaging synced with finalized detour" },
      { time: "16:12:48", text: "Economic Impact Agent engaged" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Transit and economic impact",
    status: "Transit and economic impacts calculated",
    fleetBadge: "Impact measured",
    orchestratorCopy: "Transit disruption and economic exposure are now quantified so responders can act with confidence.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Transit Coordination Agent and Economic Impact Agent have quantified the disruption.", citations: ["Transit Coordination Agent", "Economic Impact Agent", "Freight Impact Model"] }
      ],
      suggestions: [
        "Assess traffic impact",
        "Check nearby work zones",
        "Draft a public alert"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 18,
      toolCalls: 26,
      sourcesQueried: 498,
      systemsConnected: 9,
      findingsGenerated: 7
    },
    agents: [
      { name: "Incident Agent", status: "Collaborating", task: "Sharing scene updates", confidence: "86%", progress: 64, lastUpdate: "Coordinating with Traffic Ops" },
      { name: "Traffic Operations Agent", status: "Collaborating", task: "Aligning detour with work zones", confidence: "90%", progress: 82, lastUpdate: "Revised detour avoids SR-40" },
      { name: "Construction Agent", status: "Collaborating", task: "Confirming detour clearance", confidence: "87%", progress: 78, lastUpdate: "Alternate route confirmed clear" },
      { name: "Public Communications Agent", status: "Collaborating", task: "Syncing detour messaging", confidence: "90%", progress: 80, lastUpdate: "Messaging aligned with new detour" },
      { name: "Transit Coordination Agent", status: "Generating Findings", task: "Regional transit impact", confidence: "88%", progress: 84, lastUpdate: "3 bus routes rerouted, 20-min delays" },
      { name: "Economic Impact Agent", status: "Generating Findings", task: "Delay and freight cost estimate", confidence: "85%", progress: 80, lastUpdate: "$180K estimated delay cost" },
      { name: "Executive Briefing Agent", status: "Receiving Task", task: "Preparing director briefing", confidence: "--", progress: 10, lastUpdate: "Gathering inputs" }
    ],
    timeline: [
      { time: "16:12:50", text: "Transit impact quantified: 3 routes rerouted" },
      { time: "16:12:52", text: "Freight and delay cost modeled at $180K" },
      { time: "16:12:54", text: "Executive Briefing Agent engaged" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Synthesizing findings",
    status: "Synthesizing findings from all participating agents",
    fleetBadge: "Synthesis running",
    orchestratorCopy: "All findings are flowing back into the M365 Copilot orchestrator to correlate evidence, prioritize actions, and generate the director briefing.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Synthesizing findings from all participating agents.", citations: ["Gather Findings", "Correlate Evidence", "Prioritize Actions", "Generate Briefing"] }
      ],
      suggestions: [
        "Approve public alert",
        "Confirm detour plan",
        "Notify regional partners"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 18,
      toolCalls: 27,
      sourcesQueried: 555,
      systemsConnected: 9,
      findingsGenerated: 8
    },
    agents: [
      { name: "Incident Agent", status: "Returning Results", task: "Scene fully assessed", confidence: "86%", progress: 88, lastUpdate: "Final status reported" },
      { name: "Traffic Operations Agent", status: "Returning Results", task: "Detour plan finalized", confidence: "90%", progress: 90, lastUpdate: "Detour via US-42 confirmed" },
      { name: "Construction Agent", status: "Returning Results", task: "Work zone conflict resolved", confidence: "87%", progress: 88, lastUpdate: "Detour route verified clear" },
      { name: "Public Communications Agent", status: "Returning Results", task: "Alert ready for release", confidence: "90%", progress: 90, lastUpdate: "Final messaging approved" },
      { name: "Transit Coordination Agent", status: "Returning Results", task: "Transit impact finalized", confidence: "88%", progress: 88, lastUpdate: "Rerouting plan confirmed" },
      { name: "Economic Impact Agent", status: "Returning Results", task: "Cost estimate finalized", confidence: "85%", progress: 86, lastUpdate: "$180K delay cost confirmed" },
      { name: "Executive Briefing Agent", status: "Generating Findings", task: "Drafting director briefing", confidence: "84%", progress: 62, lastUpdate: "One-page briefing in progress" }
    ],
    timeline: [
      { time: "16:12:56", text: "Gather Findings pipeline initiated" },
      { time: "16:12:58", text: "Evidence correlation completed" },
      { time: "16:13:00", text: "Actions prioritized by urgency" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Top actions summary",
    status: "Top priority actions identified",
    fleetBadge: "Actions ranked",
    orchestratorCopy: "The orchestrator now prioritizes the highest-impact response actions for the Director's attention.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Top priority actions identified:", citations: ["1. Activate US-42 detour", "2. Release public alert", "3. Reroute affected transit lines"] }
      ],
      suggestions: [
        "Approve public alert",
        "Confirm detour plan",
        "Notify regional partners"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 18,
      toolCalls: 28,
      sourcesQueried: 588,
      systemsConnected: 9,
      findingsGenerated: 8
    },
    agents: [
      { name: "Incident Agent", status: "Completed", task: "Scene fully assessed", confidence: "86%", progress: 100, lastUpdate: "Hazmat cleanup underway" },
      { name: "Traffic Operations Agent", status: "Completed", task: "Detour via US-42", confidence: "90%", progress: 100, lastUpdate: "Detour signage activated" },
      { name: "Construction Agent", status: "Completed", task: "Work zone conflict resolved", confidence: "87%", progress: 100, lastUpdate: "Detour route verified clear" },
      { name: "Public Communications Agent", status: "Completed", task: "Public alert released", confidence: "90%", progress: 100, lastUpdate: "Alert live on all channels" },
      { name: "Transit Coordination Agent", status: "Completed", task: "Transit rerouting confirmed", confidence: "88%", progress: 100, lastUpdate: "Riders notified of changes" },
      { name: "Economic Impact Agent", status: "Completed", task: "Delay cost estimate", confidence: "85%", progress: 100, lastUpdate: "$180K estimated delay cost" },
      { name: "Executive Briefing Agent", status: "Generating Findings", task: "Director briefing", confidence: "91%", progress: 90, lastUpdate: "Final review in progress" }
    ],
    timeline: [
      { time: "16:13:02", text: "Top-action ranking created" },
      { time: "16:13:04", text: "Actions prioritized by urgency and impact" },
      { time: "16:13:06", text: "Director-ready briefing prepared" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  },
  {
    title: "Director briefing",
    status: "Director briefing ready",
    fleetBadge: "Mission accomplished",
    orchestratorCopy: "The M365 Copilot orchestrator has synthesized a clear one-page briefing and action plan for the Director.",
    copilot: {
      messages: [
        { role: "user", text: "A tanker truck has overturned on I-70 during rush hour. What's the impact, and what should we do right now?" },
        { role: "assistant", text: "I'll pull incident details and coordinate specialist Foundry agents to assess impact.", citations: ["CAD Feed", "Traffic Sensors", "District 6 Ops"] },
        { role: "assistant", text: "Director Briefing\n\nIncident: Tanker rollover, I-70 EB near MM 112, all lanes blocked, hazmat active\nEstimated Clearance: 3-4 hours\nProjected Delay Cost: $180K (freight and congestion)\n\nRecommended Actions\n1. Activate US-42 detour immediately\n2. Release public alert across all channels\n3. Reroute 3 affected regional transit lines\n4. Notify freight partners of extended delay window", citations: ["Executive Briefing Agent", "One-Page Director Briefing"] }
      ],
      suggestions: [
        "Approve public alert",
        "Confirm detour plan",
        "Notify regional partners"
      ]
    },
    metrics: {
      activeAgents: 7,
      tasksRunning: 18,
      toolCalls: 28,
      sourcesQueried: 612,
      systemsConnected: 9,
      findingsGenerated: 8
    },
    agents: [
      { name: "Incident Agent", status: "Completed", task: "Scene fully assessed", confidence: "86%", progress: 100, lastUpdate: "Hazmat cleanup underway" },
      { name: "Traffic Operations Agent", status: "Completed", task: "Detour via US-42", confidence: "90%", progress: 100, lastUpdate: "Detour signage activated" },
      { name: "Construction Agent", status: "Completed", task: "Work zone conflict resolved", confidence: "87%", progress: 100, lastUpdate: "Detour route verified clear" },
      { name: "Public Communications Agent", status: "Completed", task: "Public alert released", confidence: "90%", progress: 100, lastUpdate: "Alert live on all channels" },
      { name: "Transit Coordination Agent", status: "Completed", task: "Transit rerouting confirmed", confidence: "88%", progress: 100, lastUpdate: "Riders notified of changes" },
      { name: "Economic Impact Agent", status: "Completed", task: "Delay cost estimate", confidence: "85%", progress: 100, lastUpdate: "$180K estimated delay cost" },
      { name: "Executive Briefing Agent", status: "Completed", task: "Director briefing delivered", confidence: "91%", progress: 100, lastUpdate: "One-page briefing delivered" }
    ],
    timeline: [
      { time: "16:13:08", text: "Director briefing generated" },
      { time: "16:13:10", text: "Action plan prepared for the Director" },
      { time: "16:13:12", text: "Mission accomplished" }
    ],
    impact: [
      { label: "Agents coordinated", value: "7" },
      { label: "Sources reviewed", value: "612" },
      { label: "Tool calls executed", value: "24" },
      { label: "Systems accessed", value: "9" },
      { label: "Findings generated", value: "8" },
      { label: "Estimated time saved", value: "3.5 Hours" }
    ]
  }
];

// Per-agent trace log. Each entry has the scene index (0-based, matching `scenes`)
// at which the event becomes visible, so the trace grows as the story progresses.
const agentTraces = {
  "Incident Agent": [
    { step: 1, time: "16:12:02", type: "task", title: "Task received", detail: "Copilot orchestrator assigned Incident Agent to confirm scene details and monitor the tanker rollover on I-70." },
    { step: 2, time: "16:12:08", type: "tool", title: "Connected to 911/CAD Feed", detail: "Pulled dispatch records and unit assignments for the I-70 eastbound rollover." },
    { step: 3, time: "16:12:14", type: "tool", title: "Connected to Traffic Management Alerts", detail: "Confirmed all eastbound lanes blocked near mile marker 112 and hazmat unit on scene." },
    { step: 3, time: "16:12:16", type: "thought", title: "Assessing scene severity", detail: "Cross-referenced hazmat classification against lane closure duration models. Estimated 3-4 hour clearance window." },
    { step: 8, time: "16:12:43", type: "collab", title: "Collaborating with Traffic Operations Agent", detail: "Shared live scene status to support detour and congestion modeling." },
    { step: 11, time: "16:12:56", type: "collab", title: "Findings returned to orchestrator", detail: "Sent confirmed scene status and clearance estimate to Copilot for synthesis." },
    { step: 12, time: "16:13:08", type: "complete", title: "Task completed", detail: "Scene status included in the Director briefing as the incident summary." }
  ],
  "Traffic Operations Agent": [
    { step: 1, time: "16:12:02", type: "task", title: "Task received", detail: "Copilot orchestrator assigned Traffic Operations Agent to calculate congestion impact and recommend detours." },
    { step: 5, time: "16:12:25", type: "tool", title: "Connected to Statewide Traffic Management System", detail: "Pulled live sensor data on backup length and travel-time impact along I-70." },
    { step: 5, time: "16:12:27", type: "tool", title: "Connected to Navigation Data Feed", detail: "Modeled alternate route travel times for SR-40 and US-42 corridors." },
    { step: 5, time: "16:12:29", type: "thought", title: "Evaluating detour options", detail: "Congestion backup exceeds 6 miles. Initially identified SR-40 and US-42 as viable detour routes." },
    { step: 8, time: "16:12:43", type: "collab", title: "Collaborating with Construction Agent", detail: "Received work zone conflict on SR-40 and revised the detour recommendation to US-42." },
    { step: 8, time: "16:12:45", type: "collab", title: "Collaborating with Public Communications Agent", detail: "Shared the finalized US-42 detour so public messaging could be synchronized." },
    { step: 9, time: "16:12:50", type: "finding", title: "Finding: US-42 Detour Recommended", detail: "The US-42 detour avoids the SR-40 work zone conflict and adds an estimated 12 minutes to affected trips.", confidence: "90%" },
    { step: 11, time: "16:12:58", type: "collab", title: "Findings returned to orchestrator", detail: "Sent finalized detour plan and congestion model to Copilot for synthesis." },
    { step: 12, time: "16:13:08", type: "complete", title: "Task completed", detail: "Detour plan included as Priority Action #1 in the Director briefing." }
  ],
  "Construction Agent": [
    { step: 1, time: "16:12:02", type: "task", title: "Task received", detail: "Copilot orchestrator assigned Construction Agent to identify nearby work zones that could worsen traffic." },
    { step: 6, time: "16:12:31", type: "tool", title: "Connected to Work Zone Database", detail: "Queried all active lane closures within a 10-mile radius of the incident." },
    { step: 6, time: "16:12:33", type: "tool", title: "Connected to District 6 Construction Schedule", detail: "Cross-referenced planned closures against the detour corridor timeline." },
    { step: 6, time: "16:12:35", type: "thought", title: "Flagging detour conflict", detail: "Identified an active single-lane closure on SR-40 that would compound congestion if used as the primary detour." },
    { step: 8, time: "16:12:43", type: "collab", title: "Collaborating with Traffic Operations Agent", detail: "Recommended shifting the detour to US-42 to avoid the SR-40 work zone conflict." },
    { step: 9, time: "16:12:47", type: "finding", title: "Finding: Work Zone Conflict on SR-40", detail: "SR-40 has an active lane closure that would have doubled travel time for detoured traffic; US-42 is clear.", confidence: "87%" },
    { step: 11, time: "16:12:58", type: "collab", title: "Findings returned to orchestrator", detail: "Sent work zone conflict analysis to Copilot for synthesis." },
    { step: 12, time: "16:13:08", type: "complete", title: "Task completed", detail: "Work zone conflict resolution included in the Director briefing's detour rationale." }
  ],
  "Public Communications Agent": [
    { step: 1, time: "16:12:02", type: "task", title: "Task received", detail: "Copilot orchestrator assigned Public Communications Agent to prepare public alerts and media messaging." },
    { step: 7, time: "16:12:37", type: "tool", title: "Connected to Social Media Platform", detail: "Drafted an initial social media alert describing the incident and expected delays." },
    { step: 7, time: "16:12:39", type: "tool", title: "Connected to ODOT Traveler Website", detail: "Prepared a traveler alert banner with real-time incident status." },
    { step: 7, time: "16:12:41", type: "tool", title: "Connected to Media Distribution List", detail: "Drafted a media statement for regional news outlets." },
    { step: 8, time: "16:12:45", type: "collab", title: "Collaborating with Traffic Operations Agent", detail: "Updated all drafted messaging to reference the finalized US-42 detour." },
    { step: 9, time: "16:12:49", type: "finding", title: "Finding: Public Alert Ready", detail: "Social, web, and media messaging finalized and aligned with the confirmed detour route.", confidence: "90%" },
    { step: 11, time: "16:12:58", type: "collab", title: "Findings returned to orchestrator", detail: "Sent finalized public messaging package to Copilot for synthesis." },
    { step: 12, time: "16:13:08", type: "complete", title: "Task completed", detail: "Public alert release included as Priority Action #2 in the Director briefing." }
  ],
  "Transit Coordination Agent": [
    { step: 4, time: "16:12:23", type: "task", title: "Task received", detail: "Copilot orchestrator assigned Transit Coordination Agent to assess impacts to regional transit routes." },
    { step: 8, time: "16:12:48", type: "tool", title: "Connected to Regional Transit System", detail: "Reviewed bus routes crossing the I-70 corridor near the incident." },
    { step: 8, time: "16:12:45", type: "thought", title: "Identifying affected routes", detail: "Determined 3 regional bus routes cross the closed segment and require rerouting via the US-42 detour." },
    { step: 9, time: "16:12:50", type: "finding", title: "Finding: 3 Routes Rerouted", detail: "Three regional bus routes were rerouted via US-42, adding an estimated 20 minutes to affected trips.", confidence: "88%" },
    { step: 11, time: "16:12:58", type: "collab", title: "Findings returned to orchestrator", detail: "Sent transit rerouting plan and rider impact estimate to Copilot for synthesis." },
    { step: 12, time: "16:13:08", type: "complete", title: "Task completed", detail: "Transit rerouting included as Priority Action #3 in the Director briefing." }
  ],
  "Economic Impact Agent": [
    { step: 8, time: "16:12:48", type: "task", title: "Task received", detail: "Copilot orchestrator assigned Economic Impact Agent to estimate delay costs and freight impacts." },
    { step: 9, time: "16:12:50", type: "tool", title: "Connected to Freight Impact Model", detail: "Modeled freight delay costs based on the estimated 3-4 hour clearance window and detour length." },
    { step: 9, time: "16:12:52", type: "thought", title: "Estimating total delay cost", detail: "Combined freight delay, fuel cost, and lost productivity estimates for the affected corridor." },
    { step: 9, time: "16:12:52", type: "finding", title: "Finding: $180K Estimated Delay Cost", detail: "Total estimated economic impact of the incident, including freight delay and congestion costs, is $180K.", confidence: "85%" },
    { step: 11, time: "16:12:58", type: "collab", title: "Findings returned to orchestrator", detail: "Sent economic impact estimate to Copilot for synthesis." },
    { step: 12, time: "16:13:08", type: "complete", title: "Task completed", detail: "Delay cost estimate included in the Director briefing's impact summary." }
  ],
  "Executive Briefing Agent": [
    { step: 9, time: "16:12:54", type: "task", title: "Task received", detail: "Copilot orchestrator assigned Executive Briefing Agent to create a one-page briefing for the Director." },
    { step: 10, time: "16:12:56", type: "tool", title: "Connected to Briefing Template System", detail: "Loaded the standard one-page incident briefing template for Director-level communications." },
    { step: 10, time: "16:12:58", type: "collab", title: "Collaborating with all specialist agents", detail: "Gathered findings from Incident, Traffic Operations, Construction, Public Communications, Transit Coordination, and Economic Impact agents." },
    { step: 11, time: "16:13:00", type: "thought", title: "Prioritizing recommended actions", detail: "Ranked recommended actions by urgency: detour activation, public alert release, transit rerouting, and freight partner notification." },
    { step: 12, time: "16:13:06", type: "finding", title: "Finding: Director Briefing Drafted", detail: "One-page briefing summarizing incident status, cost impact, and four recommended actions is ready for review.", confidence: "91%" },
    { step: 12, time: "16:13:08", type: "complete", title: "Task completed", detail: "Director briefing delivered with full supporting evidence from all participating agents." }
  ]
};

function getAgentStateAtStep(agentName, stepIndex) {
  for (let i = stepIndex; i >= 0; i -= 1) {
    const agent = scenes[i].agents.find((a) => a.name === agentName);
    if (agent) return agent;
  }
  return null;
}

const stepIndicator = document.getElementById("stepIndicator");
const prevBtn = document.getElementById("prevBtn");
const nextBtn = document.getElementById("nextBtn");
const playBtn = document.getElementById("playBtn");
const pauseBtn = document.getElementById("pauseBtn");
const restartBtn = document.getElementById("restartBtn");
const themeToggle = document.getElementById("themeToggle");
const chatStatus = document.getElementById("chatStatus");
const copilotThread = document.getElementById("copilotThread");
const suggestions = document.getElementById("suggestions");
const metricsGrid = document.getElementById("metricsGrid");
const agentGrid = document.getElementById("agentGrid");
const timeline = document.getElementById("timeline");
const impactGrid = document.getElementById("impactGrid");
const fleetBadge = document.getElementById("fleetBadge");
const orchestratorCopy = document.getElementById("orchestratorCopy");
const traceOverlay = document.getElementById("traceOverlay");
const traceAgentName = document.getElementById("traceAgentName");
const traceStatusBadge = document.getElementById("traceStatusBadge");
const traceMeta = document.getElementById("traceMeta");
const traceSteps = document.getElementById("traceSteps");
const traceClose = document.getElementById("traceClose");

let currentStep = 0;
let playing = false;
let playTimer = null;

function formatMetricLabel(key) {
  const labels = {
    activeAgents: "Active Agents",
    tasksRunning: "Tasks Running",
    toolCalls: "Tool Calls Executing",
    sourcesQueried: "Sources Queried",
    systemsConnected: "Systems Connected",
    findingsGenerated: "Findings Generated"
  };
  return labels[key] || key;
}

function getStatusClass(status) {
  const normalized = status.toLowerCase();
  if (normalized.includes("idle")) return "idle";
  if (normalized.includes("receiving")) return "receiving";
  if (normalized.includes("planning")) return "planning";
  if (normalized.includes("thinking") || normalized.includes("analyzing")) return "thinking";
  if (normalized.includes("calling") || normalized.includes("tool")) return "calling";
  if (normalized.includes("collaborating")) return "collaborating";
  if (normalized.includes("generating") || normalized.includes("returning")) return "generating";
  if (normalized.includes("completed")) return "completed";
  return "idle";
}

function renderMetrics(scene) {
  const entries = Object.entries(scene.metrics);
  metricsGrid.innerHTML = entries
    .map(([key, value]) => `
      <div class="metric-card">
        <div class="metric-value">${value}</div>
        <div class="metric-label">${formatMetricLabel(key)}</div>
      </div>
    `)
    .join("");
}

function renderAgents(scene) {
  agentGrid.innerHTML = scene.agents
    .map((agent) => `
      <div class="agent-card ${getStatusClass(agent.status)}" data-status="${agent.status}" data-agent="${agent.name}" role="button" tabindex="0" aria-label="View trace for ${agent.name}">
        <div class="agent-header-row">
          <div class="agent-name">${agent.name}</div>
          <span class="agent-status-badge">${agent.status}</span>
        </div>
        <div class="agent-task">${agent.task}</div>
        <div class="agent-meta">
          <div class="meta-group">
            <span class="meta-label">Confidence</span>
            <span class="meta-value">${agent.confidence}</span>
          </div>
          <div class="meta-group">
            <span class="meta-label">Progress</span>
            <span class="meta-value">${agent.progress}%</span>
          </div>
        </div>
        <div class="progress-shell">
          <span style="width: ${agent.progress}%"></span>
        </div>
        <div class="agent-update">Last update: ${agent.lastUpdate}</div>
        <div class="agent-trace-hint">View trace →</div>
      </div>
    `)
    .join("");

  agentGrid.querySelectorAll(".agent-card").forEach((card) => {
    card.addEventListener("click", () => openTrace(card.dataset.agent));
    card.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        openTrace(card.dataset.agent);
      }
    });
  });
}

const traceTypeLabels = {
  task: "Task Assigned",
  tool: "Tool Call",
  thought: "Reasoning",
  collab: "Collaboration",
  finding: "Finding",
  complete: "Completed"
};

function openTrace(agentName) {
  const events = (agentTraces[agentName] || []).filter((event) => event.step <= currentStep);
  const agentState = getAgentStateAtStep(agentName, currentStep);

  traceAgentName.textContent = agentName;
  traceStatusBadge.textContent = agentState ? agentState.status : "Idle";
  traceStatusBadge.className = `trace-status-badge ${getStatusClass(agentState ? agentState.status : "Idle")}`;
  traceMeta.textContent = agentState
    ? `Confidence ${agentState.confidence} · Progress ${agentState.progress}% · ${events.length} logged event${events.length === 1 ? "" : "s"}`
    : "No activity yet";

  if (events.length === 0) {
    traceSteps.innerHTML = `<div class="trace-empty">This agent has not been engaged yet at this point in the story. Advance the demo to see its trace populate.</div>`;
  } else {
    traceSteps.innerHTML = events
      .map((event) => `
        <div class="trace-step trace-${event.type}">
          <div class="trace-step-icon"></div>
          <div class="trace-step-body">
            <div class="trace-step-header">
              <span class="trace-step-type">${traceTypeLabels[event.type] || event.type}</span>
              <span class="trace-step-time">${event.time}</span>
            </div>
            <div class="trace-step-title">${event.title}</div>
            <div class="trace-step-detail">${event.detail}</div>
            ${event.confidence ? `<div class="trace-step-confidence">Confidence: ${event.confidence}</div>` : ""}
          </div>
        </div>
      `)
      .join("");
  }

  traceOverlay.classList.add("open");
  document.body.classList.add("trace-open");
}

function closeTrace() {
  traceOverlay.classList.remove("open");
  document.body.classList.remove("trace-open");
}

traceClose.addEventListener("click", closeTrace);
traceOverlay.addEventListener("click", (event) => {
  if (event.target === traceOverlay) closeTrace();
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && traceOverlay.classList.contains("open")) closeTrace();
});

function renderTimeline(scene) {
  timeline.innerHTML = scene.timeline
    .slice(-5)
    .map((event) => `
      <div class="timeline-item">
        <div class="timeline-time">${event.time}</div>
        <div class="timeline-text">${event.text}</div>
      </div>
    `)
    .join("");
}

function renderImpact(scene) {
  impactGrid.innerHTML = scene.impact
    .map((item) => `
      <div class="impact-item">
        <span class="impact-label">${item.label}</span>
        <strong>${item.value}</strong>
      </div>
    `)
    .join("");
}

function renderSuggestions(scene) {
  suggestions.innerHTML = scene.copilot.suggestions
    .map((suggestion) => `<button class="suggestion-pill">${suggestion}</button>`)
    .join("");
}

function renderCopilot(scene) {
  const messageMarkup = scene.copilot.messages
    .map((message) => {
      const bubbleClass = message.role === "user" ? "user" : "assistant";
      const accent = message.role === "assistant" ? "assistant-accent" : "";
      const citations = message.citations
        ? `<div class="citations ${accent}">${message.citations.map((item) => `<span>${item}</span>`).join("")}</div>`
        : "";

      const isMultiLine = message.text.includes("\n");
      const textMarkup = isMultiLine
        ? message.text
            .split("\n")
            .map((line) => line.trim())
            .filter(Boolean)
            .map((line) => `<div class="multi-line">${line}</div>`)
            .join("")
        : message.text;

      return `
        <div class="message-row ${bubbleClass}">
          <div class="avatar ${bubbleClass}">${bubbleClass === "user" ? "U" : "C"}</div>
          <div class="bubble ${bubbleClass}">
            <div class="bubble-text">${textMarkup}</div>
            ${citations}
          </div>
        </div>
      `;
    })
    .join("");

  copilotThread.innerHTML = messageMarkup;
  copilotThread.scrollTop = copilotThread.scrollHeight;
}

function renderScene() {
  const scene = scenes[currentStep];
  stepIndicator.textContent = `Step ${currentStep + 1} of ${scenes.length}`;
  chatStatus.textContent = scene.status;
  fleetBadge.textContent = scene.fleetBadge;
  orchestratorCopy.innerHTML = `<div class="copy-header">Coordinator</div><p>${scene.orchestratorCopy}</p>`;

  renderMetrics(scene);
  renderAgents(scene);
  renderTimeline(scene);
  renderImpact(scene);
  renderSuggestions(scene);
  renderCopilot(scene);

  prevBtn.disabled = currentStep === 0;
  nextBtn.textContent = currentStep === scenes.length - 1 ? "▶ Final" : "▶ Next";

  if (traceOverlay.classList.contains("open")) {
    openTrace(traceAgentName.textContent);
  }
}

function goToStep(index) {
  const boundedIndex = Math.max(0, Math.min(index, scenes.length - 1));
  currentStep = boundedIndex;
  renderScene();
}

function stopPlayback() {
  playing = false;
  if (playTimer) {
    clearInterval(playTimer);
    playTimer = null;
  }
}

function playAll() {
  if (playing) return;
  playing = true;
  playTimer = setInterval(() => {
    if (currentStep >= scenes.length - 1) {
      stopPlayback();
      return;
    }
    currentStep += 1;
    renderScene();
  }, 3600);
}

prevBtn.addEventListener("click", () => {
  stopPlayback();
  goToStep(currentStep - 1);
});

nextBtn.addEventListener("click", () => {
  stopPlayback();
  if (currentStep >= scenes.length - 1) {
    goToStep(0);
    return;
  }
  goToStep(currentStep + 1);
});

playBtn.addEventListener("click", () => {
  if (currentStep >= scenes.length - 1) {
    currentStep = 0;
  }
  playAll();
  renderScene();
});

pauseBtn.addEventListener("click", () => {
  stopPlayback();
});

restartBtn.addEventListener("click", () => {
  stopPlayback();
  currentStep = 0;
  renderScene();
});

themeToggle.addEventListener("click", () => {
  document.body.classList.toggle("dark-mode");
  const isDark = document.body.classList.contains("dark-mode");
  themeToggle.textContent = isDark ? "Light mode" : "Dark mode";
});

renderScene();
