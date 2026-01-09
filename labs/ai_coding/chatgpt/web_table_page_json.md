# STAGE: WEB_TABLE_PAGE_JSON

## 此阶段任务

- 请根据用户提供的【Java Entity / 多表结构 / 枚举定义】等信息，自动生成一个【管理后台列表页面需求定义 JSON】。
- 该 JSON 将被直接用于后续 AI 自动生成前端（Vue + Element UI / Element Plus）以及后端接口代码，因此必须满足以下严格要求。

## 整体要求

1. 输出结果【只能是 JSON】，不能包含任何解释性文字、注释或 Markdown。
2. JSON 结构必须符合下方给定的「页面需求定义规范」。
3. 字段选择必须“以用户视角为主”，而不是数据库视角。
4. 在列表中尽量展现绝大部分字段。
5. 在查询和操作判断，无需涉及所以字段，只选择最适合在页面中涉及的字段。
6. 字段命名、label、交互设计要“像真实成熟系统”。

## 页面建模原则（非常重要）

### 主表与多表关系处理
    - 如果存在多个表：
        - 选择一个作为【页面主实体】（通常是业务核心表）
        - 其他表只用于：
            - 补充展示字段（如名称、状态、类型）
            - 查询条件

### 查询条件（queryForm）生成规则
    - 查询条件数量：**3–7个**
    - 优先级顺序：
        1. 名称 / 标题类（模糊查询）
        2. 状态 / 枚举类（Select）
        3. 时间范围（createTime / updateTime）
        4. 关键业务属性（如类型、分类等）
        5. 其他
    - 查询字段必须：
        - 对用户理解友好
        - 具有实际筛选价值
    - 不要使用：
        - 纯 ID
        - 技术标记字段
    - 如果是 枚举类（Select）selectOption 中的 value 必须使用显示枚举即 “枚举类.NAME”的方式，不能是数字或字符串常量。
    - operator 合理选择：
        - like：名称、描述
        - eq：数值、ID、状态、枚举
        - between：时间

### 表格列（table.columns）生成规则
    - Table 列数量：**5–12 列**
    - 列选择优先级：
        1. 核心业务标识（名称 / 编号）
        2. 业务状态（枚举）
        3. 关键业务属性（如时长、类型、数量）
        4. 时间字段
        5. 文件ID or URL （如 图片、音频、视频）
    - 枚举字段：
        - type = "enum"
        - formatter = "enum"
    - 时间字段：
        - type = "datetime"
    - 数值字段：
        - 提供合理 formatter

### 操作设计（Actions）
    - pageActions（页面级）
        - 通常包含：
            - create（新增）
            - batchDelete（批量删除）
        - 其它常规批量操作，需要更具具体业务选择合适的，不是必选：
            - export（导出）
            - import（导入）
            - activate（激活）
            - deactivate（停用）
            - resetPassword（重置密码）
            - assignRole（分配角色）
            - assignPermission（分配权限）
            - bindGroup（绑定分组）
            - unbindGroup（解绑分组）
            - syncData（同步数据）
            - generateReport（生成报表）
            - archive（归档）
            - unarchive（取消归档）
            - approve（审批）
            - reject（拒绝）
            - sendNotification（发送通知）
            - publish（发布）
            - unpublish（取消发布）
            - lock（锁定）
            - unlock（解锁）
            - assignTask（分配任务）
            - markAsCompleted（标记为完成）
            - duplicate（复制）
            - merge（合并）
        - 参数只在必要时传递（如 selectedIds）

    - rowActions（行级）
        - 通常包含：
            - edit
            - delete
        - 一些不可逆的危险操作默认需要 confirm = true

## 页面需求定义 JSON 规范

- 生成的 JSON 必须包含以下顶层结构：
    - code
    - name
    - layout
    - queryForm
    - pageActions
    - table
    - rowActions

- JSON 字段格式示例（结构必须一致）：

```text
{
"code": "xxx",
"name": "xxx管理",
"layout": "manage",
"queryForm": { ... },
"pageActions": [ ... ],
"table": { ... },
"rowActions": [ ... ]
}
```

## 输出质量要求

- label 使用中文、符合业务语义
- 字段选择体现“成熟产品经理判断”
- 不要出现占位字段
- 不要输出未在 Java 模型中出现、且无法推断来源的字段
- 输出结果必须是合法 JSON， 并且必须完全符合下方提供的 JSON Schema。
- 如果某个字段不适用，请不要输出该字段，而不是随意扩展结构。
- 输出要严格符合一下JSON Schema：

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://example.com/schema/page-definition.schema.json",
  "title": "Manage Page Definition Schema",
  "type": "object",
  "required": [
    "code",
    "name",
    "layout",
    "queryForm",
    "pageActions",
    "table",
    "rowActions"
  ],
  "additionalProperties": false,
  "properties": {
    "code": {
      "type": "string",
      "description": "页面唯一标识"
    },
    "name": {
      "type": "string",
      "description": "页面名称"
    },
    "layout": {
      "type": "string",
      "enum": [
        "manage"
      ]
    },
    "queryForm": {
      "type": "object",
      "required": [
        "fields"
      ],
      "additionalProperties": false,
      "properties": {
        "fields": {
          "type": "array",
          "minItems": 1,
          "maxItems": 7,
          "items": {
            "$ref": "#/$defs/queryField"
          }
        }
      }
    },
    "pageActions": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/pageAction"
      }
    },
    "table": {
      "type": "object",
      "required": [
        "columns"
      ],
      "additionalProperties": false,
      "properties": {
        "columns": {
          "type": "array",
          "minItems": 3,
          "maxItems": 12,
          "items": {
            "$ref": "#/$defs/tableColumn"
          }
        }
      }
    },
    "rowActions": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/rowAction"
      }
    }
  },
  "$defs": {
    "queryField": {
      "type": "object",
      "required": [
        "name",
        "label",
        "component",
        "operator"
      ],
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": "string"
        },
        "label": {
          "type": "string"
        },
        "component": {
          "type": "string",
          "enum": [
            "input",
            "select",
            "dateRange"
          ]
        },
        "operator": {
          "type": "string",
          "enum": [
            "eq",
            "in",
            "like",
            "between"
          ]
        },
        "options": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/selectOption"
          }
        }
      },
      "allOf": [
        {
          "if": {
            "properties": {
              "component": {
                "const": "select"
              }
            }
          },
          "then": {
            "required": [
              "options"
            ]
          }
        }
      ]
    },
    "selectOption": {
      "type": "object",
      "required": [
        "value",
        "label"
      ],
      "additionalProperties": false,
      "properties": {
        "value": {
          "type": [
            "string",
            "number"
          ]
        },
        "label": {
          "type": "string"
        }
      }
    },
    "pageAction": {
      "type": "object",
      "required": [
        "code",
        "label"
      ],
      "additionalProperties": false,
      "properties": {
        "code": {
          "type": "string"
        },
        "label": {
          "type": "string"
        },
        "params": {
          "type": "array",
          "items": {
            "type": "string"
          }
        }
      }
    },
    "tableColumn": {
      "type": "object",
      "required": [
        "field",
        "label",
        "type"
      ],
      "additionalProperties": false,
      "properties": {
        "field": {
          "type": "string"
        },
        "label": {
          "type": "string"
        },
        "type": {
          "type": "string",
          "enum": [
            "string",
            "int",
            "long",
            "bool",
            "enum",
            "datetime"
          ]
        },
        "formatter": {
          "type": "string",
          "enum": [
            "text",
            "short_text",
            "long_text",
            "count",
            "amount",
            "time",
            "enum",
            "datetime",
            "img_file_id",
            "video_file_id",
            "audio_file_id"
          ]
        },
        "sortable": {
          "type": "boolean"
        },
        "format": {
          "type": "string"
        }
      }
    },
    "rowAction": {
      "type": "object",
      "required": [
        "code",
        "label"
      ],
      "additionalProperties": false,
      "properties": {
        "code": {
          "type": "string"
        },
        "label": {
          "type": "string"
        },
        "confirm": {
          "type": "boolean",
          "default": false
        }
      }
    }
  }
}
```

