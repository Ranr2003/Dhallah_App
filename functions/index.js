const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
    admin.initializeApp();
}

// 1. وظيفة إشعارات الدردشة (عند إنشاء رسالة جديدة)
exports.sendChatNotification = onDocumentCreated('chat_rooms/{roomId}/messages/{messageId}', async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;

    const messageData = snapshot.data();
    const receiverId = messageData.receiverId;
    const senderId = messageData.senderId;
    const text = messageData.message;

    try {
        const [senderDoc, receiverDoc] = await Promise.all([
            admin.firestore().collection('users').doc(senderId).get(),
            admin.firestore().collection('users').doc(receiverId).get()
        ]);

        const senderName = senderDoc.exists ? (senderDoc.data().name || "شخص ما") : "شخص ما";
        const fcmToken = receiverDoc.exists ? receiverDoc.data().fcmToken : null;

        if (fcmToken) {
            await admin.messaging().send({
                notification: { title: `رسالة جديدة من ${senderName}`, body: text },
                token: fcmToken,
                data: { roomId: event.params.roomId, type: 'chat' },
            });
        }

        // حفظ في سجل الإشعارات للجرس
        await admin.firestore().collection('notifications').add({
            receiverId: receiverId,
            title: `رسالة جديدة من ${senderName}`,
            body: text,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            type: 'chat',
        });

        console.log("✅ Chat notification processed");
    } catch (error) {
        console.error("❌ Chat error:", error);
    }
    return null;
});

// 2. وظيفة إشعارات التطابق الذكي (عند تحديث البلاغ بـ matches جديدة)
exports.sendMatchNotification = onDocumentUpdated('reports/{reportId}', async (event) => {
    if (!event.data || !event.data.after) return null;

    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();
    const reportId = event.params.reportId;

    const extractIds = (list) => {
        if (!list || !Array.isArray(list)) return [];
        return list.map(m => (typeof m === 'object' ? m.matched_report_id : m)).filter(id => id);
    };

    const newMatchIds = extractIds(newValue.matches);
    const oldMatchIds = extractIds(previousValue.matches);

    if (newMatchIds.length <= oldMatchIds.length) return null;

    try {
        const userDoc = await admin.firestore().collection('users').doc(newValue.userId).get();
        if (!userDoc.exists) return null;

        const fcmToken = userDoc.data().fcmToken;
        const category = (newValue.item && newValue.item.category) ? newValue.item.category : "عنصر";
        const title = `تطابق جديد لبلاغ ${category} ✨`;
        const body = "وجدنا نتائج جديدة تطابق مواصفات بلاغك، تفقدها الآن.";

        await admin.firestore().collection('notifications').add({
            receiverId: newValue.userId,
            reportId: reportId,
            title: title,
            body: body,
            type: 'match',
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (fcmToken) {
            await admin.messaging().send({
                notification: { title, body },
                token: fcmToken,
                data: { reportId: reportId, type: 'match' }
            });
        }
        console.log("✅ Match notification processed");
    } catch (error) {
        console.error("❌ Match error:", error);
    }
    return null;
});

// 3. وظيفة إشعارات إغلاق البلاغ (التهنئة)
exports.sendReportClosedNotification = onDocumentUpdated('reports/{reportId}', async (event) => {
    if (!event.data || !event.data.after) return null;

    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();

    const isNowClosed = newValue.status === 'closed' || newValue.status === 'found';
    const wasAlreadyClosed = previousValue.status === 'closed' || previousValue.status === 'found';

    if (isNowClosed && !wasAlreadyClosed) {
        try {
            const userDoc = await admin.firestore().collection('users').doc(newValue.userId).get();
            if (!userDoc.exists) return null;

            const fcmToken = userDoc.data().fcmToken;
            const title = "تم إغلاق البلاغ بنجاح 🎉";
            const body = "شكراً لاستخدامك ضالة، ونتمنى لك يوماً سعيداً.";

            await admin.firestore().collection('notifications').add({
                receiverId: newValue.userId,
                title: title,
                body: body,
                type: 'congrats',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            if (fcmToken) {
                await admin.messaging().send({
                    notification: { title, body },
                    token: fcmToken,
                    data: { type: 'congrats' }
                });
            }
        } catch (error) {
            console.error("❌ Congrats error:", error);
        }
    }
    return null;
});