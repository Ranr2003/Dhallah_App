const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
    admin.initializeApp();
}

exports.sendMatchNotification = onDocumentUpdated('reports/{reportId}', async (event) => {
    // التحقق من وجود بيانات لتجنب الانهيار
    if (!event.data || !event.data.after) return null;

    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();
    const reportId = event.params.reportId;

    // 1. استخراج التصنيف بشكل صحيح من حقل item
    const category = (newValue.item && newValue.item.category) ? newValue.item.category : "عنصر";

    // 2. التحقق من المصفوفة الصحيحة (matches) كما يفعل الـ AI Worker
    // نحولها لمصفوفة معرفات نصوص للمقارنة بسهولة
    const extractIds = (list) => {
        if (!list || !Array.isArray(list)) return [];
        return list.map(m => (typeof m === 'object' ? m.matched_report_id : m)).filter(id => id);
    };

    const newMatchIds = extractIds(newValue.matches);
    const oldMatchIds = extractIds(previousValue.matches);

    // إذا لم تكن هناك مطابقات جديدة، لا نفعل شيئاً
    if (newMatchIds.length <= oldMatchIds.length) return null;

    try {
        // جلب بيانات المستخدم لإرسال FCM
        const userDoc = await admin.firestore().collection('users').doc(newValue.userId).get();
        if (!userDoc.exists) return null;

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        const title = `تطابق جديد لبلاغ ${category} ✨`;
        const body = "وجدنا نتائج جديدة تطابق مواصفات بلاغك، تفقدها الآن.";

        // حفظ الإشعار في Firestore ليظهر في قائمة الإشعارات
        await admin.firestore().collection('notifications').add({
            receiverId: newValue.userId,
            reportId: reportId,
            title: title,
            body: body,
            notifiedMatchIds: newMatchIds,
            type: 'match',
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // إرسال الإشعار عبر السحاب
        if (fcmToken) {
            await admin.messaging().send({
                notification: { title, body },
                token: fcmToken,
                data: {
                    reportId: reportId,
                    type: 'match',
                    click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                android: {
                    notification: {
                        channelId: "matches_channel_id", // يجب أن يطابق ما وضعناه في فلاتر
                        priority: "high"
                    }
                }
            });
            console.log(`✅ Sent notification to user: ${newValue.userId}`);
        }
    } catch (error) {
        console.error("❌ Error processing notification:", error);
    }
    return null;
});
// --- 2. الدالة الجديدة: إشعار إغلاق البلاغ (التهنئة) ---
exports.sendReportClosedNotification = onDocumentUpdated('reports/{reportId}', async (event) => {
    if (!event.data || !event.data.after) return null;

    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();

    // نتحقق إذا تغيرت الحالة من أي شيء إلى "closed" أو "found"
    // (تأكدي من مطابقة الكلمة لما هو موجود في تطبيق فلاتر عندك)
    const isNowClosed = newValue.status === 'closed' || newValue.status === 'found';
    const wasAlreadyClosed = previousValue.status === 'closed' || previousValue.status === 'found';

    if (isNowClosed && !wasAlreadyClosed) {
        try {
            const userDoc = await admin.firestore().collection('users').doc(newValue.userId).get();
            if (!userDoc.exists) return null;

            const fcmToken = userDoc.data().fcmToken;
            const title = "تم إغلاق البلاغ بنجاح 🎉";
            const body = "سعداء جداً لأنك وجدت غرضك! شكراً لاستخدامك ضالة ، ونتمنى لك يوماً سعيداً.";

            // حفظ في قائمة الإشعارات
            await admin.firestore().collection('notifications').add({
                receiverId: newValue.userId,
                reportId: event.params.reportId,
                title: title,
                body: body,
                type: 'congrats',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // الإرسال للهاتف
            if (fcmToken) {
                await admin.messaging().send({
                    notification: { title, body },
                    token: fcmToken,
                    data: { type: 'congrats' }
                });
                console.log(`✅ Congrats notification sent to: ${newValue.userId}`);
            }
        } catch (error) {
            console.error("❌ Error in sendReportClosedNotification:", error);
        }
    }
    return null;
});