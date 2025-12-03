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
TestStringsProvider (به‌روزرسانی rows)
      |
      v
TestStringsPage (بازرندر شدن UI)

3. ساختار پوشه‌ی lib/ با توضیح

درخت کلی:

lib/
  main.dart                      // نقطه‌ی ورود اپ، init کلاینت و تعریف Provider و Routeها

  config/
    environment.dart             // ثابت‌های محیطی و شناسه‌های Appwrite (endpoint, projectId, DB, collection)
    network/
      api_result.dart            // مدل جنریک ApiResult<T> برای برگشت موفق/ناموفق از شبکه
      appwrite_client.dart       // Singleton برای Client, Databases, Realtime و تنظیم JWT/Session
      network_error.dart         // مدل یک‌دست خطاهای شبکه + مپ شدن AppwriteException به NetworkErrorType
      realtime_manager.dart      // مدیریت subscribe/unsubscribe به کانال‌های Realtime و تولید RealtimeEvent<T>
      request_executor.dart      // لایه‌ی اجرای امن درخواست‌ها (try/catch، timeout، لاگ) و تولید ApiResult<T>

  data/
    models/
      test_string.dart           // مدل دامنه‌ای TestString (نماینده‌ی سطرهای کالکشن test_strings)
    repository/
      base_crud_repository.dart  // ریپازیتوری جنریک CRUD برای Appwrite Databases (getAll, getById, create, update, delete)
      test_strings_repository.dart // ریپازیتوری اختصاصی برای TestString که IDs را از Environment می‌گیرد

  state/
    connection_provider.dart     // ChangeNotifier برای تست اتصال (Ping) به Appwrite و نگه‌داری وضعیت + لاگ‌ها
    test_strings_provider.dart   // ChangeNotifier اصلی صفحه test_strings؛ شامل rows، پیجینگ، Realtime و CRUD

  page/
    appwritestarterkit.dart      // UI تست اتصال: دکمه Ping + نمایش وضعیت و لاگ‌ها (با GetWidget + Shimmer)
    test_strings_page.dart       // UI CRUD + لیست با infinite scroll، شیمِر، دیالوگ Add/Edit/Delete و استفاده از AppNotifier

  utils/
    app_notifier.dart            // سیستم Toast سفارشی فارسی (بالای صفحه، RTL، با انیمیشن slide+fade)

خلاصه‌ی کلاس‌ها (کامنت کنار هر کلاس)

main.dart

main() – مقداردهی اولیه‌ی AppwriteClient و اجرای اپ

MyApp – تعریف تم و MultiProvider (ConnectionProvider + TestStringsProvider) و Routeها

HomePage – صفحه‌ی ساده‌ی ورود، شامل دکمه‌ی رفتن به صفحات تست (/test-strings و /starter-kit)

config/environment.dart

Environment – ثابت‌های پروژه: آدرس سرور Appwrite، projectId، databaseId، collectionIdTestStrings و ...

config/network/api_result.dart

ApiResult<T> – نتیجه‌ی استاندارد درخواست‌ها:

data / error

isSuccess / isFailure

requireData / requireError

success(), successNoData(), failure()

config/network/appwrite_client.dart

AppwriteClient – Singleton:

نگه‌داری Client, Databases, Realtime

متد init() برای تنظیم endpoint/project

متدهای setJWT, setSession, reset

گترهای type-safe با چک کردن برقرار بودن init

config/network/network_error.dart

NetworkErrorType – enum انواع خطا: network, server, unauthorized, forbidden, notFound, timeout, validation, cancelled, serialization, unknown

NetworkError – مدل واحد خطا:

type, userMessage, devMessage, statusCode, code, originalException, details …

factoryهای کمکی: network(), timeout(), server(), unauthorized()، ...

NetworkError.fromAppwriteException() برای تبدیل مستقیم AppwriteException به خطای قابل‌فهم

config/network/request_executor.dart

NetworkLogger – اینترفیس ساده برای لاگ کردن

ConsoleNetworkLogger – پیاده‌سازی ساده‌ی logger با print

RequestExecutor – لایه‌ی اجرای امن:

متد جنریک execute<T>(Future<T> Function() action, {timeout, label, mapErrorMessage})

مدیریت:

TimeoutException → NetworkError.timeout

SocketException → NetworkError.network

AppwriteException → NetworkError.fromAppwriteException

سایر Exception/خطاها → NetworkError.unknown

بسته‌بندی خروجی به صورت ApiResult<T>

config/network/realtime_manager.dart

RealtimeAction – enum (create, update, delete, unknown)

RealtimeEvent<T> – مدل رویداد ریل‌تایم:

action

data (به صورت T)

documentId

raw (Map خام Appwrite)

RealtimeManager – مدیریت اشتراک:

subscribeRaw(channels) – برگرداندن Stream<RealtimeEvent<Map>>

subscribeCollection<T>(databaseId, collectionId, fromJson) – استریم تایپ‌شده برای یک کالکشن

_extractAction() – تبدیل لیست message.events به RealtimeAction

unsubscribe(channels) و unsubscribeCollection() و dispose()

داخلش با یک StreamController.broadcast و RealtimeSubscription کار می‌کند تا چند Listener داشته باشیم

data/models/test_string.dart

TestString – مدل سطرهای کالکشن test_strings:

فیلدها: id, text, createdAt, updatedAt

fromJson() – دیکد هم data معمولی هم متادیتای Appwrite ($id, $createdAt, $updatedAt)

toJson() – داده‌ای که برای create/update به Appwrite فرستاده می‌شود

copyWith() – برای ساخت نسخه‌ی جدید با تغییر بخشی از فیلدها

data/repository/base_crud_repository.dart

BaseCrudRepository<T> – ریپازیتوری جنریک:

کانستراکتور: databaseId, collectionId, fromJson, toJson

استفاده از AppwriteClient.instance.databases و RequestExecutor

_documentToMap(Document) – ادغام doc.data با متادیتا ($id, $createdAt, ...)

getAll({queries}) – لیست مستندها (با پشتیبانی از Queryها مثل orderDesc, limit, cursorAfter)

getById(documentId) – خواندن یک داکیومنت

create(entity, {documentId, permissions})

update(documentId, entity, {permissions})

delete(documentId)

data/repository/test_strings_repository.dart

TestStringsRepository – ریپازیتوری اختصاصی:

Extend از BaseCrudRepository<TestString>

تنظیم databaseId و collectionId از Environment

پاس دادن TestString.fromJson و value.toJson()

state/connection_provider.dart

ConnectionProvider (ChangeNotifier) – مسئول تست اتصال به Appwrite:

State:

isPinging, lastSuccess, lastMessage, lastPingAt

logs (لیست رشته‌ها)

sendPing():

جلوگیری از اجرای هم‌زمان

استفاده از Databases از AppwriteClient

اجرای یک listDocuments خیلی سبک با Query.limit(1) از طریق RequestExecutor

تنظیم lastSuccess, lastMessage, lastPingAt

نوشتن لاگ‌ها در logs (با timestamp)

clearLogs() – خالی کردن لیست لاگ‌ها و notifyListeners

state/test_strings_provider.dart

TestStringsProvider (ChangeNotifier) – قلب بخش CRUD:

State:

rows – لیست TestStringها

loading – لود اولیه

isLoadingMore – لود صفحه‌های بعدی

hasMore – آیا دیتای بیشتری برای صفحه‌های بعد وجود دارد؟

_cursorAfter – ID برای pagination با cursor

_loadedIds – Set<String> برای جلوگیری از تکرار رکوردها

error – پیام خطا برای نمایش در UI

_realtimeSub – subscription روی Realtime

چرخه‌ی عمر:

سازنده → _init() → _loadInitialRows() + _subscribeToRealtime()

dispose() → لغو subscription

_loadInitialRows():

ریست state و پاک کردن rows و _loadedIds

صدا زدن ریپازیتوری:

Query.orderDesc('$updatedAt') → جدیدترین‌ها بالاتر

Query.limit(_pageSize) → صفحه‌ی اول (در حال حاضر ۱۵ تایی)

در صورت خطا: تنظیم error و loading=false

در صورت موفقیت:

پر کردن rows و اضافه کردن IDها به _loadedIds

مرتب‌سازی مجدد با _sortRowsByUpdatedAt() (اگر updatedAt نبود از createdAt استفاده می‌شود)

تنظیم hasMore = items.length >= _pageSize

اگر hasMore بود → _cursorAfter = items.last.id

refresh() – برای Pull-To-Refresh احتمالی، دوباره _loadInitialRows() را صدا می‌زند

loadMore() – صفحه‌های بعدی (Infinite Scroll):

اگر در حال لود اولیه یا لودMore هستیم یا hasMore == false → هیچ کاری نکن

ساخت queries:

Query.orderDesc('$updatedAt')

Query.limit(_pageSize)

اگر _cursorAfter تنظیم شده بود → Query.cursorAfter(_cursorAfter!)

دریافت صفحه‌ی بعدی با getAll(queries: queries)

در صورت خطا: isLoadingMore=false + error

در صورت موفقیت:

اگر items.isEmpty → hasMore=false

برای هر آیتم:

اگر rows آن id را ندارد → اضافه کردن به لیست و _loadedIds

اگر داشت → به‌روزرسانی رکورد قبلی

مرتب‌سازی مجدد با _sortRowsByUpdatedAt()

تنظیم hasMore و _cursorAfter با توجه به طول items

_subscribeToRealtime() – اشتراک روی Realtime:

استفاده از RealtimeManager.instance.subscribeCollection<TestString>(...)

در eventها:

delete → حذف رکورد از rows و _loadedIds

create:

اگر قبلاً نبود → rows.insert(0, data) و اضافه به _loadedIds

اگر بود → آپدیت رکورد

update:

اگر در rows بود → آپدیت

اگر نبود (مثلاً در صفحه‌های قبلی بوده، حالا آپدیت شده) → insert(0, data) و اضافه به _loadedIds

unknown → فقط برای دیباگ لاگ می‌گیرد

در انتها همیشه _sortRowsByUpdatedAt() + notifyListeners()

CRUDهای قابل‌استفاده از UI:

Future<ApiResult<TestString>> create(String text)

Future<ApiResult<TestString>> update(TestString row, String newText)

Future<ApiResult<void>> delete(TestString row)

نکته مهم: این متدها، خودشان rows را دست‌کاری نمی‌کنند، بلکه روی Realtime تکیه می‌کنند؛ این باعث می‌شود تنها «منبع حقیقت» وضعیت، خروجی سرور باشد.

page/appwritestarterkit.dart

AppwriteStarterKit – صفحه تست اتصال:

کارت وضعیت اتصال (GFCard + GFListTile):

رنگ و متن (Connected / Connection error / Not pinged yet) بر اساس lastSuccess

ردیف دکمه‌ها:

دکمه‌ی Ping (GFButton):

در حالت isPinging → با Shimmer رو دکمه، متن "Pinging..."

در حالت عادی → Ping Appwrite

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

روی کلیک → _showAddEditDialog(context) برای افزودن رکورد

نمایش خطا:

اگر provider.error != null → یک GFCard قرمز کم‌رنگ با آیکن خطا و متن خطا

بدنه‌ی اصلی:

اگر loading && rows.isEmpty → فراخوانی _buildShimmerList():

چند GFCard شبیه skeleton با Shimmer برای نمایش حالت لود اولیه

اگر rows.isEmpty ولی لود تمام شده → متن No rows yet

در غیر این صورت:

یک NotificationListener<ScrollNotification> که وقتی به پایین لیست نزدیک می‌شویم و hasMore == true و isLoadingMore == false، متد provider.loadMore() را صدا می‌زند

ListView.separated:

itemCount = rows.length + (isLoadingMore ? 1 : 0)

اگر index به اندازه‌ی rows.length رسید و isLoadingMore == true → آیتم لودینگ پایین لیست (کارت شیمری _buildShimmerCard)

اگر !provider.hasMore && rows.isNotEmpty و index در انتها باشد → _buildEndOfListCard() که در کارت سبزرنگ/خوش‌استایل می‌گوید: «دیگه موردی برای نمایش نیست.»

در غیر این صورت → آیتم معمولی:

GFCard + GFListTile با:

titleText برابر متن

subTitleText شامل ID: ...

icon یک Row شامل دو GFIconButton:

edit → _showAddEditDialog(context, row: row)

delete → _showDeleteDialog(context, row)

_showAddEditDialog() – دیالوگ مشترک افزودن/ویرایش:

اگر row == null → حالت «افزودن»

اگر row != null → حالت «ویرایش»

محتوای دیالوگ:

TextField برای متن

نمایش خطای لوکال زیر فیلد در صورت مشکل

دکمه‌ها:

«انصراف» → GFButton outline

دکمه‌ی اصلی:

حالت عادی → GFButton با متن «ثبت» یا «ویرایش»

در حال submit (isSubmitting) → دکمه disabled و داخلش یک Shimmer روی GFButton کوچک به عنوان loading

اگر submit قبلی خطا داشته → متن دکمه تبدیل به «تلاش مجدد ثبت» یا «تلاش مجدد ویرایش»

منطق submit:

ولیدیشن خالی نبودن متن

صدا زدن provider.create یا provider.update

در صورت موفقیت:

Navigator.pop

AppNotifier.showSuccess(context, 'پیام موفقیت مناسب')

در صورت خطا:

تنظیم localError با error.userMessage

نمایش AppNotifier.showNetworkError(context, err)

_showDeleteDialog() – دیالوگ حذف:

متن سؤال + نمایش متن آیتم

دکمه‌های «انصراف» و «حذف»

دکمه «حذف»:

در حال submit → دکمه disabled + Shimmer روی GFButton کوچک

در خطا → متن «تلاش مجدد حذف»

روی موفقیت حذف → AppNotifier.showSuccess و بستن دیالوگ

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

_toastTimer و _overlayEntry برای کنترل عمر توست

_showToast(context, message, type):

اگر توست قبلی باز است → cancel + remove

پیدا کردن Overlay از context

ساخت OverlayEntry با _createOverlayEntry(...)

insert کردن overlay

تنظیم تایمر برای حذف بعد از چند ثانیه

_createOverlayEntry():

تعیین رنگ و آیکن بر اساس AppToastType

ساخت Positioned در بالای صفحه (top: mediaQuery.padding.top + 12)

پیچاندن محتوا در Directionality(textDirection: TextDirection.rtl) تا کل پیام راست به چپ شود

استفاده از SlideInToastMessageAnimation برای انیمیشن:

ورود از بالا به پایین، مکث، و خروج دوباره به بالا

بدنه‌ی اصلی:

Material با elevation و borderRadius

Container با padding و پس‌زمینه‌ی رنگی

Row:

ابتدا Expanded حاوی Text(message) (justify به راست، فونت سفید)

سپس آیکن دایره‌ای متناسب با نوع toast

SlideInToastMessageAnimation – ویجت stateful:

کنترلر انیمیشن و دو Animation (opacity و translateY)

توالی:

۰ → ۱ opacity و حرکت از Y = -100 به 0 (ورود)

مکث

۱ → ۰ opacity و حرکت از 0 به -100 (خروج)

انیمیشن روی child اعمال می‌شود

4. پیجینگ (Pagination) و Infinite Scroll

هدف:
لیست test_strings همواره بر اساس آخرین زمان به‌روزرسانی ($updatedAt) مرتب است؛ داده‌ها ۱۵ تا ۱۵ تا ( _pageSize = 15 ) از سرور گرفته می‌شوند؛ وقتی کاربر به انتهای لیست اسکرول می‌کند، صفحه‌ی بعدی به‌صورت اتوماتیک درخواست می‌شود.

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

_loadedIds تمام IDهایی که تا الان گرفته‌ایم را نگه می‌دارد.

در loadMore() اگر ID قبلًا وجود داشته باشد، آیتم فقط به‌روزرسانی می‌شود نه اضافه.

Realtime + Paging:

اگر در حین اسکرول، داده‌ای در سرور ایجاد/ویرایش شود:

Realtime آن را دریافت می‌کند

اگر رکورد جدید باشد → بالای لیست insert(0, data) می‌شود

اگر رکورد موجود باشد → همان رکورد آپدیت می‌شود

در هر حالت بعد از دریافت Realtime، _sortRowsByUpdatedAt() اجرا می‌شود تا لیست همیشه بر اساس آخرین تغییر مرتب باشد.

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

یک کلاس در data/repository بساز که از BaseCrudRepository<MyEntity> ارث‌بری می‌کند و databaseId/collectionId را ست می‌کند.

Provider

یک ChangeNotifier مثل TestStringsProvider در state/ اضافه کن:

State، _loadInitialRows, loadMore, _subscribeToRealtime, CRUD

صفحه‌ی UI

یک صفحه در page/ تعریف کن، با ListView/Dialogs و اتصال به Provider

اتصال به اپ

Provider جدید را در MultiProvider داخل main.dart اضافه کن

Route جدید برای صفحه تعریف کن

پیغام‌ها

برای نمایش پیام، از AppNotifier.showSuccess(...) و AppNotifier.showNetworkError(...) استفاده کن تا همه‌جا تجربه‌ی یکسانی داشته باشی.

این داکیومنت عملاً کل ساختار و رفتار پروژه‌ی فعلی را پوشش می‌دهد؛ خواننده با همین توضیحات می‌تواند بدون دیدن کد، بفهمد:

هر پوشه و هر کلاس چه وظیفه‌ای دارد،

لایه‌ی شبکه چگونه کار می‌کند،

Providerها چه حالتی را نگه می‌دارند،

پیجینگ و Realtime چگونه با هم ترکیب شده‌اند،

و سیستم نمایش پیام‌ها (توست‌ها) چطور در سراسر پروژه استفاده می‌شود.
