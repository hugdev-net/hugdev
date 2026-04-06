function main(config) {
    // =========================================================
    // 0. 配置区：所有需要经常调整的内容都放这里
    // =========================================================
    const SETTINGS = {
        // ---------- 分组名称 ----------
        groupNames: {
            staticResidence: "🏠 静态住宅",
            normalLanding: "🚪 普通落地",
            overseasExit: "🌍 海外出口",
            others: "📦 其它情况"
        },

        proxyNames: {
            staticResidenceNode: "🏠 静态住宅节点"
        },

        // ---------- 注入的静态住宅节点 ----------
        // 说明：
        // 1) 静态住宅节点本身是 socks5
        // 2) 通过 “海外出口” 组做 dialer-proxy，实现链式代理
        residentialProxy: {
            name: "🏠 静态住宅节点",
            type: "socks5",
            server: "x.x.x.x",
            port: 1234,
            username: "username",
            password: "password",
            udp: true
            // dialer-proxy 会在下面自动补成 “🌍 海外出口”
        },

        // ---------- 三个可正则筛选的订阅分组 ----------
        // include: 命中任一正则即纳入
        // exclude: 命中任一正则即排除
        //
        // 可按你的订阅命名习惯自行修改
        groupFilters: {
            normalLanding: {
                include: [
                    /日本/i,
                    /jp/i
                ],
                exclude: []
            },
            overseasExit: {
                include: [
                    /香港/i,
                    /hk/i,
                    /台湾/i,
                    /tw/i,
                    /日本/i,
                    /jp/i,
                    /新加坡/i,
                    /sg/i,
                    /韩国/i,
                    /kr/i
                ],
                exclude: []
            },
            others: {
                include: [
                    /美国/i,
                    /US/i
                ],
                exclude: []
            }
        },

        // ---------- 分组类型 ----------
        // 可改成 select / url-test / fallback 等
        groupTypes: {
            normalLanding: "url-test",
            overseasExit: "url-test",
            others: "select"
        },

        // ---------- url-test 通用参数 ----------
        urlTest: {
            url: "https://www.gstatic.com/generate_204",
            interval: 180,
            tolerance: 50
        },

        // ---------- rule-providers：这里只配置 url ----------
        ruleProviderUrls: {
            openai:
                "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/OpenAI/OpenAI.yaml",
            anthropic:
                "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Claude/Claude.yaml",
            gemini:
                "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Gemini/Gemini.yaml"
        },

        // ---------- 需要前插的规则 ----------
        // AI 相关统一走 “静态住宅”
        prependRules: [
            // 封锁主流 DoH 服务商，强制回退到系统 DNS（由 Clash 接管）
            "DOMAIN,dns.google,REJECT",
            "DOMAIN,dns64.dns.google,REJECT",
            "DOMAIN,cloudflare-dns.com,REJECT",
            "DOMAIN,1dot1dot1dot1.cloudflare-dns.com,REJECT",
            "DOMAIN,doh.opendns.com,REJECT",
            "DOMAIN,doh.familyshield.opendns.com,REJECT",
            // dns.alidns.com 和 doh.pub 若被 Clash DNS 使用，不应 REJECT
            "DOMAIN,dns.quad9.net,REJECT",

            // Claude Desktop / 相关进程
            "PROCESS-NAME,Claude.exe,🏠 静态住宅",
            "PROCESS-NAME,cowork-svc.exe,🏠 静态住宅",

            // Anthropic / Claude 域名
            "DOMAIN,api.anthropic.com,🏠 静态住宅",
            "DOMAIN-SUFFIX,anthropic.com,🏠 静态住宅",
            "DOMAIN-SUFFIX,claude.ai,🏠 静态住宅",
            "DOMAIN-SUFFIX,openai.com,🏠 静态住宅",
            "DOMAIN-SUFFIX,google.com,🏠 静态住宅",
            "DOMAIN-KEYWORD,google,🏠 静态住宅",
            "DOMAIN-SUFFIX,ping0.cc,🏠 静态住宅",

            // 规则集兜底
            "RULE-SET,openai,🏠 静态住宅",
            "RULE-SET,anthropic,🏠 静态住宅",
            "RULE-SET,gemini,🏠 静态住宅",

            "DOMAIN-SUFFIX,microsoft.com,🚪 普通落地",
            "DOMAIN-SUFFIX,msn.com,🚪 普通落地",


            // 国内应用直连
            "PROCESS-NAME,Foxmail.exe,DIRECT",
            "PROCESS-NAME,WeChatAppEx.exe,DIRECT",

            // 向日葵直连
            "PROCESS-NAME,SunloginClient.exe,DIRECT",
            "PROCESS-NAME,SunloginClientService.exe,DIRECT",
            "PROCESS-NAME,SunloginHost.exe,DIRECT",
            "DOMAIN-SUFFIX,oray.com,DIRECT",
            "DOMAIN-SUFFIX,oray.net,DIRECT",
            "DOMAIN-SUFFIX,sunlogin.net,DIRECT",
            "DOMAIN-SUFFIX,sunlogin.com.cn,DIRECT"
        ],

        // ---------- 首个原始订阅组中插入哪些组 ----------
        injectIntoFirstOriginalGroup: [
            "🏠 静态住宅",
            "🚪 普通落地",
            "🌍 海外出口",
            "📦 其它情况"
        ],

        // ---------- fake-ip-filter 补充 ----------
        fakeIpFilterEntries: [
            "+.oray.com",
            "+.oray.net",
            "+.sunlogin.net",
            "+.sunlogin.com.cn",
            "+.263em.com"
        ]
    };

    // =========================================================
    // 1. 工具函数
    // =========================================================

    function ensureArray(v) {
        return Array.isArray(v) ? v : [];
    }

    function ensureObject(v) {
        return v && typeof v === "object" && !Array.isArray(v) ? v : {};
    }

    function uniqueStrings(arr) {
        return [...new Set(ensureArray(arr).filter(v => typeof v === "string"))];
    }

    function upsertByName(list, item) {
        const idx = list.findIndex(x => x && x.name === item.name);
        if (idx >= 0) {
            list[idx] = item;
        } else {
            list.unshift(item);
        }
    }

    function matchesFilter(name, filter) {
        const include = ensureArray(filter?.include);
        const exclude = ensureArray(filter?.exclude);

        const included =
            include.length === 0 || include.some(reg => reg instanceof RegExp && reg.test(name));

        const excluded =
            exclude.length > 0 && exclude.some(reg => reg instanceof RegExp && reg.test(name));

        return included && !excluded;
    }

    function getAllSubscriptionProxyNames(proxies, extraExcludedNames = []) {
        const excluded = new Set(extraExcludedNames);
        return ensureArray(proxies)
            .map(p => p?.name)
            .filter(name => typeof name === "string" && !excluded.has(name));
    }

    function selectProxyNamesByFilter(proxies, filter, extraExcludedNames = []) {
        const excluded = new Set(extraExcludedNames);
        return ensureArray(proxies)
            .map(p => p?.name)
            .filter(name => typeof name === "string")
            .filter(name => !excluded.has(name))
            .filter(name => matchesFilter(name, filter));
    }

    function inferRuleProviderBehaviorFromUrl(url) {
        const u = String(url).toLowerCase();

        // 粗略推导，常见场景够用；不命中则默认 domain
        if (u.includes("/classical/")) return "classical";
        if (u.includes("/ipcidr/") || u.includes("/ip-cidr/")) return "ipcidr";
        if (u.includes("/domain/")) return "domain";

        // blackmatrix7 这类 AI 规则通常可按 domain 处理
        return "domain";
    }

    function inferRuleProviderPath(name, url) {
        const urlFile = String(url).split("/").pop() || `${name}.yaml`;
        const safeFile = urlFile.endsWith(".yaml") ? urlFile : `${name}.yaml`;
        return `./ruleset/${safeFile}`;
    }

    function buildRuleProviders(urlMap) {
        const result = {};
        Object.entries(ensureObject(urlMap)).forEach(([name, url]) => {
            result[name] = {
                type: "http",
                behavior: inferRuleProviderBehaviorFromUrl(url),
                format: "yaml",
                url,
                path: inferRuleProviderPath(name, url),
                interval: 86400
            };
        });
        return result;
    }

    function buildSelectGroup(name, proxies) {
        return {
            name,
            type: "select",
            proxies: uniqueStrings(proxies)
        };
    }

    function buildUrlTestGroup(name, proxies, urlTestConfig) {
        return {
            name,
            type: "url-test",
            proxies: uniqueStrings(proxies),
            url: urlTestConfig.url,
            interval: urlTestConfig.interval,
            tolerance: urlTestConfig.tolerance
        };
    }

    function buildGroupByType(name, type, proxies, urlTestConfig) {
        if (type === "url-test") {
            return buildUrlTestGroup(name, proxies, urlTestConfig);
        }
        return buildSelectGroup(name, proxies);
    }

    function prependRulesWithoutDup(existingRules, prependRules) {
        const normalizedExisting = new Set(
            ensureArray(existingRules).map(r => (typeof r === "string" ? r : JSON.stringify(r)))
        );

        const newRules = ensureArray(prependRules).filter(
            r => typeof r === "string" && !normalizedExisting.has(r)
        );

        return [...newRules, ...ensureArray(existingRules)];
    }

    function insertGroupsIntoFirstOriginalGroup(proxyGroups, namesToInsert, injectedGroupNames) {
        const firstOriginalGroup = ensureArray(proxyGroups).find(
            g => g && !injectedGroupNames.has(g.name)
        );

        if (!firstOriginalGroup || !Array.isArray(firstOriginalGroup.proxies)) return;

        for (let i = namesToInsert.length - 1; i >= 0; i--) {
            const groupName = namesToInsert[i];
            if (!firstOriginalGroup.proxies.includes(groupName)) {
                firstOriginalGroup.proxies.unshift(groupName);
            }
        }
    }

    // =========================================================
    // 2. 初始化配置对象
    // =========================================================
    config = ensureObject(config);
    config.proxies = ensureArray(config.proxies);
    config["proxy-groups"] = ensureArray(config["proxy-groups"]);
    config["rule-providers"] = ensureObject(config["rule-providers"]);
    config.rules = ensureArray(config.rules);
    config.dns = ensureObject(config.dns);
    config.dns["fake-ip-filter"] = ensureArray(config.dns["fake-ip-filter"]);

    // =========================================================
    // 3. 注入静态住宅节点（通过“海外出口”链式代理）
    // =========================================================
    const residentialProxy = {
        ...SETTINGS.residentialProxy,
        "dialer-proxy": SETTINGS.groupNames.overseasExit
    };
    upsertByName(config.proxies, residentialProxy);

    // =========================================================
    // 4. 基于正则，从订阅节点中筛选三个分组的成员
    // =========================================================
    // 注意：
    // - 只筛选订阅节点，不把注入的“静态住宅”再参与筛选
    // - “其它情况” 默认你可配 /.*/，也可以改成更具体的规则
    const injectedProxyNames = new Set([SETTINGS.proxyNames.staticResidenceNode]);

    const normalLandingProxies = selectProxyNamesByFilter(
        config.proxies,
        SETTINGS.groupFilters.normalLanding,
        injectedProxyNames
    );

    const overseasExitProxies = selectProxyNamesByFilter(
        config.proxies,
        SETTINGS.groupFilters.overseasExit,
        injectedProxyNames
    );

    const othersProxies = selectProxyNamesByFilter(
        config.proxies,
        SETTINGS.groupFilters.others,
        injectedProxyNames
    );

    // 为避免分组为空导致体验差，这里做一个兜底
    const allSubscriptionProxies = getAllSubscriptionProxyNames(config.proxies, injectedProxyNames);

    const safeNormalLandingProxies =
        normalLandingProxies.length > 0 ? normalLandingProxies : allSubscriptionProxies;

    const safeOverseasExitProxies =
        overseasExitProxies.length > 0 ? overseasExitProxies : allSubscriptionProxies;

    const safeOthersProxies =
        othersProxies.length > 0 ? othersProxies : allSubscriptionProxies;

    // =========================================================
    // 5. 构建四个目标分组
    // =========================================================
    const staticResidenceGroup = buildSelectGroup(
        SETTINGS.groupNames.staticResidence,
        [SETTINGS.proxyNames.staticResidenceNode]
    );

    const normalLandingGroup = buildGroupByType(
        SETTINGS.groupNames.normalLanding,
        SETTINGS.groupTypes.normalLanding,
        safeNormalLandingProxies,
        SETTINGS.urlTest
    );

    const overseasExitGroup = buildGroupByType(
        SETTINGS.groupNames.overseasExit,
        SETTINGS.groupTypes.overseasExit,
        safeOverseasExitProxies,
        SETTINGS.urlTest
    );

    const othersGroup = buildGroupByType(
        SETTINGS.groupNames.others,
        SETTINGS.groupTypes.others,
        safeOthersProxies,
        SETTINGS.urlTest
    );

    // 用 upsert，保证重复执行脚本时不会重复插入
    upsertByName(config["proxy-groups"], othersGroup);
    upsertByName(config["proxy-groups"], overseasExitGroup);
    upsertByName(config["proxy-groups"], normalLandingGroup);
    upsertByName(config["proxy-groups"], staticResidenceGroup);

    // =========================================================
    // 6. 将四个分组插入到订阅的第一个原始代理组前面
    // =========================================================
    const injectedGroupNames = new Set([
        SETTINGS.groupNames.staticResidence,
        SETTINGS.groupNames.normalLanding,
        SETTINGS.groupNames.overseasExit,
        SETTINGS.groupNames.others
    ]);

    insertGroupsIntoFirstOriginalGroup(
        config["proxy-groups"],
        SETTINGS.injectIntoFirstOriginalGroup,
        injectedGroupNames
    );

    // =========================================================
    // 7. 注入 rule-providers（配置时只写 url，这里自动展开）
    // =========================================================
    Object.assign(
        config["rule-providers"],
        buildRuleProviders(SETTINGS.ruleProviderUrls)
    );

    // =========================================================
    // 8. 前插规则（自动去重）
    // =========================================================
    config.rules = prependRulesWithoutDup(config.rules, SETTINGS.prependRules);

    // =========================================================
    // 9. DNS fake-ip-filter 补充
    // =========================================================
    for (const entry of SETTINGS.fakeIpFilterEntries) {
        if (!config.dns["fake-ip-filter"].includes(entry)) {
            config.dns["fake-ip-filter"].push(entry);
        }
    }

    return config;
}