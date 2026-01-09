# STAGE: JAVA_BEAN

## 此阶段任务

- 请根据用户提供的信息，自动生成 JAVA 实体类。

## 生成 JavaBeans 的整体要求

- 建议生成的类中的字段遵循驼峰命名法，如果原始字段为小写且以下划线分隔，则应在 Java 字段中使用适当的注释。
- 建议在类上添加诸如： @Data、 @ToString、 @SuperBuilder、 @AllArgsConstructor、 @NoArgsConstructor 这样的注解。
- 不要生成 getter 和 setter 方法。
- 类和其每一个字段都要有Schema注解，请生成何理Schema 的name 和 description 的值。
- 如果字段类似 密码的敏感数据，为了不记录到日志，字段应该添加以下注解： @ToString.Exclude、 @JsonIgnore、 @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
- 请确保生成的 JavaBean 代码符合 Java 编码规范，并且易于阅读和维护。

## 生成用于 Controller 方法的参数 JavaBeans 的额外要求

- 类名建议以 "Param" 结尾。
- 类需要 implements AbstractParam
- 字段上需要添加 @NotEmpty、@NotNull、@Max、@Min等注解，具体取决于字段的使用场景。

## 生成用于 Controller 方法的返回结果 JavaBeans 的额外要求

- 类名建议以 "Result" 结尾。
- 类需要 implements AbstractResult
