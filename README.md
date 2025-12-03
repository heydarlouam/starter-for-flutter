Appwrite Flutter Starter Kit – مستند معماری
1. هدف پروژه

این پروژه یک نمونه‌ی «استارتر کیت» برای کار با Appwrite در Flutter است که این موارد را یک‌جا نشان می‌دهد:

لایه‌ی شبکه‌ی جنریک و قابل‌استفاده‌مجدد

مدیریت حالت با Provider (بدون Bloc)

کار با Appwrite Databases + Realtime

پیاده‌سازی CRUD روی یک کالکشن ساده (test_strings)

Pagination اسکرولی (Infinite Scroll) روی لیست

Skeleton / Shimmer Loading برای تجربه‌ی لود بهتر

نمایش پیام‌های موفقیت/خطا با یک سیستم Toast سفارشی (فارسی، RTL)

ایمن‌سازی ChangeNotifierها و عملیات async با یک BaseProvider مشترک

2. دیاگرام کلی معماری

جریان اصلی داده و مسئولیت لایه‌ها به این شکل است:

                 +------------------------+
                 |       UI (page/)       |
                 |------------------------|
                 | TestStringsPage        |
                 | AppwriteStarterKit     |
                 +------------+-----------+
                              |
                     (Provider / context.watch)
                              v
                 +------------------------+
                 |     State (state/)     |
                 |------------------------|
                 | BaseProvider           |
                 | TestStringsProvider    |
                 | ConnectionProvider     |
                 +------------+-----------+
                              |
                         calls Repos
                              v
                 +------------------------+
                 |   Data / Repository    |
                 |------------------------|
                 | BaseCrudRepository<T>  |
                 | TestStringsRepository  |
                 +------------+-----------+
                              |
                     uses Network Layer
                              v
                 +------------------------+
                 |    Network (config/)   |
                 |------------------------|
                 | AppwriteClient         |
                 | RequestExecutor        |
                 | ApiResult<T>           |
                 | NetworkError           |
                 | RealtimeManager        |
                 +------------+-----------+
                              |
                           Appwrite
                 (Databases + Realtime API)


Realtime مسیر برگشتی را هم پوشش می‌دهد:

Appwrite Realtime
|
v
RealtimeManager ---> Stream<RealtimeEvent<T>>
|
v
TestStringsProvider (به‌روزرسانی rows + هماهنگی با CRUD)
|
v
TestStringsPage (بازرندر شدن UI)

3. ساختار پوشه‌ی lib/ با توضیح

درخت کلی:

lib/
main.dart                      // نقطه‌ی ورود اپ، init AppwriteClient و تعریف Provider و Routeها

config/
environment.dart             // ثابت‌های محیطی و شناسه‌های Appwrite (endpoint, projectId, DB, collections)
network/
api_result.dart            // مدل جنریک ApiResult<T> برای موفق/ناموفق بودن درخواست‌های شبکه
appwrite_client.dart       // Singleton برای Client, Databases, Realtime و مدیریت JWT/Session
network_error.dart         // مدل یک‌دست خطای شبکه + مپ شدن AppwriteException به NetworkErrorType
realtime_manager.dart      // مدیریت subscribe/unsubscribe به کانال‌های Realtime و تولید RealtimeEvent<T>
request_executor.dart      // اجرای امن درخواست‌ها (try/catch, timeout, لاگ) و تبدیل به ApiResult<T>

data/
models/
test_string.dart           // مدل دامنه‌ای TestString (سطرهای کالکشن test_strings)
repository/
base_crud_repository.dart  // ریپازیتوری جنریک CRUD برای Databases (getAll, getById, create, update, delete)
test_strings_repository.dart // ریپازیتوری اختصاصی TestString با IDs گرفته‌شده از Environment

state/
base_provider.dart           // BaseProvider مشترک برای همه‌ی Providerها (محافظت در برابر notify بعد از dispose)
connection_provider.dart     // Provider تست اتصال (Ping) به Appwrite و نگه‌داری وضعیت/لاگ
test_strings_provider.dart   // Provider اصلی CRUD + Paging + Realtime برای کالکشن test_strings

page/
appwritestarterkit.dart      // UI تست اتصال: دکمه Ping + نمایش وضعیت و لاگ‌ها
test_strings_page.dart       // UI CRUD: لیست با infinite scroll، شیمِر، دیالوگ Add/Edit/Delete و Toast

utils/
app_notifier.dart            // سیستم Toast سفارشی فارسی (RTL، انیمیشن slide+fade و تضمین فقط یک toast فعال)


خلاصه‌ی کلاس‌ها (کامنت کنار هر کلاس)
main.dart

main() – مقداردهی اولیه‌ی AppwriteClient و اجرای اپ

MyApp – تعریف تم و MultiProvider (برای ConnectionProvider و TestStringsProvider) و Routeها

HomePage – صفحه‌ی ساده‌ی ورود، شامل دکمه‌ی رفتن به صفحات تست (/test-strings و /starter-kit)

config/environment.dart

Environment – ثابت‌های پروژه:

آدرس سرور Appwrite، projectId

databaseId، collectionIdTestStrings

سایر شناسه‌های موردنیاز

config/network/api_result.dart

ApiResult<T> – نتیجه‌ی استاندارد درخواست‌ها:

فیلدها:

data / error

پراپرتی‌ها:

isSuccess / isFailure

متدهای کمکی:

requireData / requireError

success(), successNoData(), failure()

config/network/appwrite_client.dart

AppwriteClient – Singleton:

نگه‌داری Client, Databases, Realtime

متد init() برای تنظیم endpoint / project

متدهای setJWT, setSession, reset

getterهای type-safe با چک کردن برقرار بودن init
(اگر قبل از init استفاده شود، خطای واضح می‌دهد)

config/network/network_error.dart

NetworkErrorType – enum انواع خطا:

network, server, unauthorized, forbidden, notFound, timeout,
validation, cancelled, serialization, unknown

NetworkError – مدل یک‌دست خطاهای شبکه:

type, userMessage, devMessage, statusCode, code, originalException, details …

factoryهای کمکی: network(), timeout(), server(), unauthorized()، …

NetworkError.fromAppwriteException() برای تبدیل مستقیم AppwriteException به خطای قابل‌فهم

config/network/request_executor.dart

NetworkLogger – اینترفیس ساده برای لاگ کردن

ConsoleNetworkLogger – پیاده‌سازی ساده‌ی logger با print

RequestExecutor – لایه‌ی اجرای امن:

متد جنریک:

Future<ApiResult<T>> execute<T>(
Future<T> Function() action, {
Duration? timeout,
String? label,
String Function(Object error, StackTrace st)? mapErrorMessage,
}
)


مدیریت استثناها:

TimeoutException → NetworkError.timeout

SocketException → NetworkError.network

AppwriteException → NetworkError.fromAppwriteException

سایر Exceptionها → NetworkError.unknown

خروجی همیشه به صورت ApiResult<T> بسته‌بندی می‌شود.

config/network/realtime_manager.dart

RealtimeAction – enum: create, update, delete, unknown

RealtimeEvent<T> – مدل رویداد ریل‌تایم:

action – نوع عملیات (create/update/delete/unknown)

data – داده‌ی تایپ‌شده (T) یا null

documentId – شناسه‌ی رکورد (اگر موجود باشد)

raw – payload خام Appwrite (Map<String, dynamic>)

RealtimeManager – مدیریت اشتراک:

subscribeRaw(channels) – برگرداندن Stream<RealtimeEvent<Map<String, dynamic>>>

subscribeCollection<T>(databaseId, collectionId, fromJson) – استریم تایپ‌شده برای یک کالکشن

_extractAction() – تبدیل لیست message.events به RealtimeAction

unsubscribe(channels) و unsubscribeCollection() و dispose()

زیرپوستی با یک StreamController.broadcast و RealtimeSubscription کار می‌کند تا چند Listener هم‌زمان داشته باشیم.

data/models/test_string.dart

TestString – مدل سطرهای کالکشن test_strings:

فیلدها: id, text, createdAt, updatedAt

fromJson() – دیکد هم data معمولی هم متادیتای Appwrite ($id, $createdAt, $updatedAt)

toJson() – داده‌ای که برای create/update به Appwrite فرستاده می‌شود

copyWith() – برای ساخت نسخه‌ی جدید با تغییر بخشی از فیلدها

data/repository/base_crud_repository.dart

BaseCrudRepository<T> – ریپازیتوری جنریک:

کانستراکتور:

databaseId, collectionId

T Function(Map<String, dynamic>) fromJson

Map<String, dynamic> Function(T value) toJson

استفاده از:

AppwriteClient.instance.databases

RequestExecutor

_documentToMap(Document) – ادغام doc.data با متادیتا ($id, $createdAt, ...)

متدها:

getAll({List<String>? queries}) – لیست مستندها (با پشتیبانی از Queryها مثل orderDesc, limit, cursorAfter)

getById(documentId) – خواندن یک داکیومنت

create(entity, {String? documentId, List<String>? permissions})

update(documentId, entity, {List<String>? permissions})

delete(documentId)

data/repository/test_strings_repository.dart

TestStringsRepository – ریپازیتوری اختصاصی:

extends از BaseCrudRepository<TestString>

تنظیم databaseId و collectionId از Environment

پاس دادن TestString.fromJson و value.toJson() در کانستراکتور پدر

state/base_provider.dart

BaseProvider – کلاس پایه برای همه‌ی Providerها (به‌جای استفاده مستقیم از ChangeNotifier):

فلگ خصوصی:

bool _disposed = false;


getter اختیاری:

bool get isDisposed => _disposed;


override کردن notifyListeners():

اگر _disposed == true باشد، هیچ‌چیز notify نمی‌شود →
جلوگیری از notifyListeners بعد از dispose (سناریوهای async طولانی).

override کردن dispose():

_disposed = true;

super.dispose();

این کلاس پایه، ریپازیتوری‌ها و Providerهایی که عملیات async (مثل درخواست شبکه یا Realtime) دارند را در برابر خطاهای معمول UI مانند setState()/notifyListeners() called after dispose محافظت می‌کند.

state/connection_provider.dart

ConnectionProvider (extends BaseProvider) – مسئول تست اتصال به Appwrite:

State:

bool isPinging

bool? lastSuccess

String? lastMessage

DateTime? lastPingAt

List<String> logs

sendPing():

جلوگیری از اجرای هم‌زمان (اگر isPinging == true → return)

استفاده از Databases از AppwriteClient

اجرای یک listDocuments خیلی سبک با Query.limit(1) از طریق RequestExecutor

تنظیم lastSuccess, lastMessage, lastPingAt

نوشتن لاگ‌ها در logs (با timestamp)

اتکاء به BaseProvider برای جلوگیری از notifyListeners بعد از dispose

clearLogs() – خالی کردن لیست logs و notifyListeners()

state/test_strings_provider.dart

TestStringsProvider (extends BaseProvider) – قلب بخش CRUD + Realtime:

State:

List<TestString> rows – لیست سطرها

bool loading – لود اولیه

bool isLoadingMore – لود صفحه‌های بعدی

bool hasMore – آیا دیتای بیشتری برای صفحه‌های بعد وجود دارد؟

String? _cursorAfter – ID برای pagination با cursor

Set<String> _loadedIds – برای نگه‌داشتن IDها (برای جلوگیری از تکرار/استفاده‌های بعدی)

String? error – پیام خطا برای نمایش در UI

StreamSubscription<RealtimeEvent<TestString>>? _realtimeSub – subscription روی Realtime

چرخه‌ی عمر:

سازنده → _init() →
_loadInitialRows() + _subscribeToRealtime()

dispose() → لغو subscription (_realtimeSub?.cancel()) و سپس super.dispose()
(BaseProvider فلگ _disposed را تنظیم می‌کند و باقی notifyها را خاموش می‌کند)

_loadInitialRows():

ریست state و پاک کردن rows و _loadedIds

صدا زدن ریپازیتوری با:

Query.orderDesc('$updatedAt') → جدیدترین‌ها بالاتر

Query.limit(_pageSize) → صفحه‌ی اول (در حال حاضر ۱۵ تایی)

در صورت خطا:

error تنظیم می‌شود و loading=false

در صورت موفقیت:

پر کردن rows و اضافه کردن IDها به _loadedIds

مرتب‌سازی مجدد با _sortRowsByUpdatedAt()
(اگر updatedAt نبود از createdAt استفاده می‌شود)

تنظیم hasMore = items.length >= _pageSize

اگر hasMore بود → _cursorAfter = items.last.id

refresh() – برای Pull-To-Refresh احتمالی، دوباره _loadInitialRows() را صدا می‌زند.

loadMore() – صفحه‌های بعدی (Infinite Scroll):

اگر:

در حال لود اولیه (loading == true)

یا در حال loadMore (isLoadingMore == true)

یا hasMore == false
→ هیچ کاری نمی‌کند.

ساخت queries:

Query.orderDesc('$updatedAt')

Query.limit(_pageSize)

اگر _cursorAfter تنظیم شده بود → Query.cursorAfter(_cursorAfter!)

دریافت صفحه‌ی بعدی با getAll(queries: queries)

در صورت خطا:

isLoadingMore=false + error تنظیم می‌شود

در صورت موفقیت:

اگر items.isEmpty → hasMore=false

برای هر آیتم:

اگر در rows آن id وجود نداشت → اضافه کردن به لیست و _loadedIds

اگر وجود داشت → به‌روزرسانی رکورد قبلی

مرتب‌سازی مجدد با _sortRowsByUpdatedAt()

تنظیم hasMore و _cursorAfter با توجه به طول items

_subscribeToRealtime() – اشتراک روی Realtime:

استفاده از:

RealtimeManager.instance.subscribeCollection<TestString>(
databaseId: Environment.databaseId,
collectionId: Environment.collectionIdTestStrings,
fromJson: TestString.fromJson,
);


در eventها:

delete:

حذف رکورد از rows

حذف id از _loadedIds

create:

اگر قبلاً نبود → rows.insert(0, data) و اضافه به _loadedIds

اگر بود → آپدیت رکورد موجود

update:

اگر در rows بود → آپدیت

اگر نبود (مثلاً در صفحه‌های قبلی بوده، حالا آپدیت شده) → insert(0, data) و اضافه به _loadedIds

unknown:

فقط برای دیباگ لاگ می‌گیرد (در kDebugMode)

در انتها همیشه:

_sortRowsByUpdatedAt() + notifyListeners()

CRUDهای قابل‌استفاده از UI (با آپدیت خوش‌بینانه):

Future<ApiResult<TestString>> create(String text)

Future<ApiResult<TestString>> update(TestString row, String newText)

Future<ApiResult<void>> delete(TestString row)

این متدها بعد از موفقیت درخواست شبکه:

بلافاصله rows را به‌روزرسانی می‌کنند (اضافه/ویرایش/حذف محلی)

notifyListeners() را صدا می‌زنند تا UI سریعاً sync شود

سپس Realtime همان تغییر را تأیید می‌کند؛ اگر event دوباره برسد،
با indexWhere فقط رکورد موجود آپدیت می‌شود و تکرار ایجاد نمی‌شود.

نکته مهم:

اگر Realtime به هر دلیل قطع باشد، UI همچنان با سرور هماهنگ می‌ماند (به‌خاطر آپدیت خوش‌بینانه).

وقتی Realtime وصل باشد، سرور همچنان «منبع حقیقت» است و رویدادهای آن، state را نهایی می‌کنند.

page/appwritestarterkit.dart

AppwriteStarterKit – صفحه تست اتصال:

کارت وضعیت اتصال (GFCard + GFListTile):

رنگ و متن (Connected / Connection error / Not pinged yet) بر اساس lastSuccess

ردیف دکمه‌ها:

دکمه‌ی Ping (GFButton):

در حالت isPinging == true → با Shimmer روی دکمه، متن "Pinging..."

در حالت عادی → "Ping Appwrite"

دکمه‌ی Clear Logs (GFIconButton)

کارت لیست لاگ‌ها (GFCard):

عنوان Logs

در صورت نبود لاگ → متن راهنما

در صورت وجود لاگ → ListView.separated با استایل ساده (background روشن)

ارتفاع لاگ‌ها با SizedBox(height: 250) کنترل شده تا از خطای layout جلوگیری شود

page/test_strings_page.dart

TestStringsPage – صفحه اصلی CRUD:

AppBar: عنوان «test_strings (Realtime + Provider + Network Layer)»

floatingActionButton:

داخل GFFloatingWidget یک FloatingActionButton دارد

روی کلیک → _showAddEditDialog(context) برای افزودن رکورد جدید

نمایش خطا:

اگر provider.error != null → یک کارت قرمز کم‌رنگ با آیکن خطا و متن error

بدنه‌ی اصلی:

اگر loading && rows.isEmpty → فراخوانی _buildShimmerList():

چند GFCard شبیه skeleton با Shimmer برای نمایش حالت لود اولیه

اگر rows.isEmpty ولی لود تمام شده → متن No rows yet

در غیر این صورت:

یک NotificationListener<ScrollNotification> که وقتی به پایین لیست نزدیک می‌شویم و:

hasMore == true

isLoadingMore == false

و pixels >= maxScrollExtent - 200

آن‌گاه provider.loadMore() را صدا می‌زند.

ListView.separated:

itemCount = _calculateItemCount(provider)
(شامل آیتم‌های لودینگ/پایان لیست هم می‌شود)

اگر index به اندازه‌ی rows.length رسید:

و isLoadingMore == true → نمایش کارت شیمری لودMore

و !hasMore && rows.isNotEmpty → نمایش کارت پایان لیست (_buildEndOfListCard())

در غیر این صورت → آیتم معمولی:

GFCard + GFListTile با:

titleText: متن (row.text یا (no text))

subTitleText: شامل ID: ${row.id}

icon: Row شامل دو GFIconButton:

edit → _showAddEditDialog(context, row: row)

delete → _showDeleteDialog(context, row)

دیالوگ‌ها (ایمن در برابر async + dispose):

_showAddEditDialog() – دیالوگ مشترک افزودن/ویرایش:

اگر row == null → حالت «افزودن»

اگر row != null → حالت «ویرایش»

محتوا:

TextField برای متن

نمایش خطای لوکال زیر فیلد در صورت مشکل

دکمه‌ها:

«انصراف» → GFButton outline

دکمه‌ی اصلی:

حالت عادی → GFButton با متن «ثبت» یا «ویرایش»

در حال submit (isSubmitting) → دکمه disabled و داخلش Shimmer

در صورت خطا → متن دکمه «تلاش مجدد ثبت/ویرایش»

ایمن‌سازی Navigator:

قبل از عملیات async، یک‌بار:

final navigator = Navigator.of(dialogContext);


گرفته می‌شود.

بعد از await، قبل از pop():

if (!navigator.mounted) return;
navigator.pop();


این کار جلوی خطای Unexpected null value در Web / سناریوهای dispose وسط async را می‌گیرد.

روی موفقیت:

navigator.pop()

AppNotifier.showSuccess(context, ...)

روی خطا:

تنظیم localError با err.userMessage

AppNotifier.showNetworkError(context, err)

_showDeleteDialog() – دیالوگ حذف:

متن سؤال + نمایش متن آیتم

دکمه‌های «انصراف» و «حذف»

دکمه «حذف»:

در حال submit → دکمه disabled + Shimmer

در خطا → متن «تلاش مجدد حذف»

در موفقیت → navigator.pop() + AppNotifier.showSuccess(...)

در این‌جا نیز مانند Add/Edit، از navigator = Navigator.of(dialogContext) و چک‌کردن navigator.mounted قبل از pop() استفاده شده تا در صورت بسته‌شدن دیالوگ/route وسط عملیات async خطا رخ ندهد.

utils/app_notifier.dart

AppToastType – انواع toast: success, warning, error, info, delete

AppNotifier – API ساده برای نمایش پیام:

متدهای عمومی:

showSuccess(context, message)

showWarning(context, message)

showError(context, message)

showInfo(context, message)

showDelete(context, message)

showNetworkError(context, NetworkError)

پیاده‌سازی داخلی:

فقط یک toast در هر لحظه:

_toastTimer و _overlayEntry برای کنترل عمر toast

_showToast(context, message, type):

اگر toast قبلی باز است → cancel + remove

پیدا کردن Overlay از context

ساخت OverlayEntry با _createOverlayEntry(...)

insert کردن overlay

تنظیم تایمر برای حذف بعد از چند ثانیه

_createOverlayEntry():

تعیین رنگ و آیکن بر اساس AppToastType

ساخت Positioned در بالای صفحه (top: mediaQuery.padding.top + 12)

پیچاندن محتوا در Directionality(textDirection: TextDirection.rtl) تا پیام راست‌به‌چپ باشد

استفاده از SlideInToastMessageAnimation برای انیمیشن:

ورود از بالا، مکث، و خروج دوباره به بالا

بدنه‌ی اصلی:

Material با elevation و borderRadius

Container با padding و رنگ پس‌زمینه

Row شامل:

Expanded برای Text(message) (تراز راست، فونت سفید)

آیکن متناسب با نوع toast

SlideInToastMessageAnimation – ویجت stateful:

کنترلر انیمیشن و دو Animation (opacity و translateY)

توالی:

۰ → ۱ opacity و حرکت از Y = -100 به 0 (ورود)

مکث

۱ → ۰ opacity و حرکت از 0 به -100 (خروج)

4. پیجینگ (Pagination) و Infinite Scroll
   هدف

لیست test_strings همواره بر اساس آخرین زمان به‌روزرسانی ($updatedAt) مرتب است؛ داده‌ها ۱۵ تا ۱۵ تا (_pageSize = 15) از سرور گرفته می‌شوند؛ وقتی کاربر به انتهای لیست اسکرول می‌کند، صفحه‌ی بعدی به‌صورت اتوماتیک درخواست می‌شود.

4.1 سمت Provider (TestStringsProvider)

حالت اولیه:

_loadInitialRows() فقط صفحه‌ی اول را می‌آورد.

پیجینگ:

برای صفحه‌ی اول:

orderDesc('$updatedAt')

limit(_pageSize)

برای صفحات بعد:

همان دو Query بالا + cursorAfter(_cursorAfter!)

hasMore از روی این‌که آیا طول items به _pageSize رسیده یا نه تعیین می‌شود.

_cursorAfter همیشه id آخرین آیتم صفحه‌ی فعلی است (وقتی هنوز hasMore == true است).

جلوگیری از تکرار:

rows.indexWhere و _loadedIds کمک می‌کنند که:

اگر رکورد تکراری در صفحه‌ی بعدی باشد → فقط آپدیت شود، نه اضافه.

Realtime + Paging + آپدیت خوش‌بینانه:

اگر در حین اسکرول، داده‌ای در سرور ایجاد/ویرایش/حذف شود:

از طریق CRUD:

در صورت انجام عملیات از خود UI، لیست بلافاصله بعد از success آپدیت می‌شود.

از طریق Realtime:

اگر رکورد جدید باشد → بالای لیست insert(0, data) می‌شود.

اگر رکورد موجود باشد → همان رکورد آپدیت می‌شود.

در هر حالت بعد از دریافت Realtime، _sortRowsByUpdatedAt() اجرا می‌شود تا لیست دائماً بر اساس آخرین تغییر مرتب باشد.

4.2 سمت UI (TestStringsPage)

از NotificationListener<ScrollNotification> روی ListView استفاده شده:

اگر:

provider.hasMore == true

provider.isLoadingMore == false

scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200

آنگاه provider.loadMore() صدا زده می‌شود.

آیتم ویژه‌ی انتهای لیست:

اگر !provider.hasMore و rows.isNotEmpty:

_buildEndOfListCard() در انتهای لیست نمایش داده می‌شود با متن فارسی: «دیگه موردی برای نمایش نیست.»

Skeleton Loading:

لود اولیه → چند کارت شیمری به جای لیست واقعی

لود صفحه‌ی بعد (در حال isLoadingMore) → کارت شیمری در انتهای لیست

5. نحوه‌ی استفاده و گسترش پروژه

برای اضافه کردن یک کالکشن جدید با همین معماری:

مدل

یک کلاس در data/models بساز (MyEntity) با fromJson و toJson.

ریپازیتوری

یک کلاس در data/repository بساز که از BaseCrudRepository<MyEntity> ارث‌بری می‌کند و databaseId / collectionId را ست می‌کند.

Provider

یک Provider جدید در state/ بساز که از BaseProvider ارث می‌برد (نه مستقیماً از ChangeNotifier):

State، _loadInitialRows, loadMore, _subscribeToRealtime, CRUD

برای عملیات async همیشه از BaseProvider سود می‌بری که جلوی notifyListeners after dispose را می‌گیرد.

صفحه‌ی UI

یک صفحه در page/ تعریف کن، با ListView / Dialogها و اتصال به Provider

اتصال به اپ

Provider جدید را در MultiProvider داخل main.dart اضافه کن.

Route جدید برای صفحه تعریف کن.

پیغام‌ها

برای نمایش پیام، از AppNotifier.showSuccess(...) و AppNotifier.showNetworkError(...) استفاده کن تا همه‌جا تجربه‌ی یکسانی داشته باشی.

این داکیومنت عملاً کل ساختار و رفتار پروژه‌ی فعلی را (با BaseProvider، Realtime، CRUD، پیجینگ و UI شیمری) پوشش می‌دهد؛ خواننده با همین توضیحات می‌تواند بدون دیدن کد، بفهمد:

هر پوشه و هر کلاس چه وظیفه‌ای دارد،

لایه‌ی شبکه چگونه کار می‌کند،

Providerها چه حالتی را نگه می‌دارند و چگونه به Appwrite متصل‌اند،

پیجینگ و Realtime چگونه با هم ترکیب شده‌اند،

چگونه CRUD هم‌زمان هم به سرور و هم به state محلی اعمال می‌شود،

و سیستم نمایش پیام‌ها (Toastها) و ایمن‌سازی async (BaseProvider + NavigatorState) چطور در سراسر پروژه استفاده می‌شود.


