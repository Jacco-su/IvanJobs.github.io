---
layout: post
title: Ceph源码分析：从一个REST请求，到OSD存储。
category: ceph
---

Ceph最核心的是CRUSH算法，而要理解CRUSH算法，固然有一些文档可以参考，但终究抵不上从源代码层面的深究，这里尝试从一个RGW REST请求出发，到最终存储数据到OSD上，以整个过程触及到的代码为线索，深入学习CRUSH算法。

### rgw_op.h
这个头文件，开头有一段注释：
```
/**
 * All operations via the rados gateway are carried out by
 * small classes known as RGWOps. This class contains a req_state
 * and each possible command is a subclass of this with a defined
 * execute() method that does whatever the subclass name implies.
 * These subclasses must be further subclassed (by interface type)
 * to provide additional virtual methods such as send_response or get_params.
 */
```
可以看出，所有的REST请求到达RGW之后，都会封装成RGWOps类，该类为一个基类，包含一个req_state, 并且子类通过实现execute()方法，来实现自己的个性功能。

### RGWPutObj
这个类，猜测是用来创建一个object。可以观察到每一个RGWOp都有一个friend class,这里RGWPutObj的friend class是RGWPutObjProcessor，friend class的意思是，可以修改类的私有成员。
在继续观察RGWPutObj之前，让我们看一下它的父类RGWOp:
```
class RGWOp {
  47 protected:
  48   struct req_state *s;
  49   RGWHandler *dialect_handler;
  50   RGWRados *store;
  51   RGWCORSConfiguration bucket_cors;
  52   bool cors_exist;
  53   RGWQuotaInfo bucket_quota;
  54   RGWQuotaInfo user_quota;
  55   int op_ret;
  56
  57   int do_aws4_auth_completion();
  58
  59   virtual int init_quota();
```
这里笔者只关注这么几个成员变量：req_state *s; RGWHandler *dialect_handler; RGWRados *store; int op_ret;
这个几个变量中，请求信息保存在s中，处理请求的使用的是dialect_handler(待确认), store指针用于调用rados，op_ret是响应code（待确认）。

下面我们来看看req_state这个结构体中，是否保存了一些HTTP Request的标准信息：
```
1194 /* XXX why don't RGWRequest (or descendants) hold this state? */
1195 class RGWRequest;
1196
1197 /** Store all the state necessary to complete and respond to an HTTP request*/
1198 struct req_state {
1199   CephContext *cct;
1200   RGWClientIO *cio;
1201   RGWRequest *req; /// XXX: re-remove??
1202   http_op op;
1203   RGWOpType op_type;
1204   bool content_started;
1205   int format;
1206   ceph::Formatter *formatter;
1207   string decoded_uri;
1208   string relative_uri;
1209   const char *length;
1210   int64_t content_length;
1211   map<string, string> generic_attrs;
1212   struct rgw_err err;
1213   bool expect_cont;
1214   bool header_ended;
1215   uint64_t obj_size;
1216   bool enable_ops_log;
```
我表示看不懂了，耦合了很多业务信息。不过引出了一个RGWRequest类，我们来看看(rgw_request.h)：
```
 16 struct RGWRequest
 17 {
 18   uint64_t id;
 19   struct req_state *s;
 20   string req_str;
 21   RGWOp *op;
 22   utime_t ts;
 23
 24   explicit RGWRequest(uint64_t id) : id(id), s(NULL), op(NULL) {}
 25
 26   virtual ~RGWRequest() {}
 27
 28   void init_state(req_state *_s) {
 29     s = _s;
 30   }
 31
 32   void log_format(struct req_state *s, const char *fmt, ...);
 33   void log_init();
 34   void log(struct req_state *s, const char *msg);
 35 }; /* RGWRequest */
```
看不懂了，就此打住:(

继续研究RGWPutObj, 观察select_processor方法，注意到：
```
2292 RGWPutObjProcessor *RGWPutObj::select_processor(RGWObjectCtx& obj_ctx, bool *is_multipart)
2293 {
2294   RGWPutObjProcessor *processor;
2295
2296   bool multipart = s->info.args.exists("uploadId");
```
可以看到，通过是否存在uploadId这个参数，来判断是否为multipart上传。
可以看出QueryString的参数保存在一个叫做req_info的结构体的args里:
```
1075 struct req_info {
1076   RGWEnv *env;
1077   RGWHTTPArgs args;
1078   map<string, string> x_meta_map;
1079
1080   string host;
1081   const char *method;
1082   string script_uri;
1083   string request_uri;
1084   string effective_uri;
1085   string request_params;
1086   string domain;
1087
1088   req_info(CephContext *cct, RGWEnv *_env);
1089   void rebuild_from(req_info& src);
1090   void init_meta_info(bool *found_bad_meta);
1091 };
1092
```
最后RGWPutObj选用了RGWPutObjProcessor_Atomic来实现上传文件。
```
2300   if (!multipart) {
2301     processor = new RGWPutObjProcessor_Atomic(obj_ctx, s->bucket_info, s->bucket, s->object.name, part_s     ize, s->req_id, s->bucket_info.versioning_enabled());
2302     (static_cast<RGWPutObjProcessor_Atomic *>(processor))->set_olh_epoch(olh_epoch);
2303     (static_cast<RGWPutObjProcessor_Atomic *>(processor))->set_version_id(version_id);
```

RGWPutObjProcessor_Atomic类定义在rgw_rados.h中：
```

```

