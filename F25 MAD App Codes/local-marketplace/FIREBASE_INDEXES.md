# Firebase Firestore Indexes Required

This document lists all the composite indexes required for the GetCars app to function properly.

## Required Composite Indexes

### 1. Notifications Collection
**Collection:** `notifications`
- **Fields:**
  - `userId` (Ascending)
  - `timestamp` (Descending)
- **Query Scope:** Collection
- **Used in:** `lib/main_screens/account_subscreens/notifications_screen.dart` (line 286-287)
- **Purpose:** Fetch user-specific notifications sorted by timestamp

### 2. FAQs Collection
**Collection:** `faqs`
- **Fields:**
  - `isActive` (Ascending)
  - `timestamp` (Descending)
- **Query Scope:** Collection
- **Used in:** `lib/main_screens/account_subscreens/faq_screen.dart` (line 267-268)
- **Purpose:** Fetch active FAQs sorted by creation time

### 3. Notifications - Mark All as Read
**Collection:** `notifications`
- **Fields:**
  - `userId` (Ascending)
  - `isRead` (Ascending)
- **Query Scope:** Collection
- **Used in:** `lib/main_screens/account_subscreens/notifications_screen.dart` (line 134-135)
- **Purpose:** Find all unread notifications for a specific user

### 4. Chat Messages - Mark as Read
**Collection:** `chats/{chatId}/messages`
- **Fields:**
  - `senderId` (Ascending)
  - `isRead` (Ascending)
- **Query Scope:** Collection
- **Used in:** `lib/services/chat_service.dart` (line 140-141)
- **Purpose:** Mark unread messages from other users as read

## How to Create Indexes

### Option 1: Automatic Creation (Recommended)
1. Run the app and trigger the queries that need indexes
2. Firebase will show an error with a direct link to create the index
3. Click the link and wait for the index to be built (usually 1-2 minutes)

### Option 2: Manual Creation via Firebase Console
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Enter the collection name and add fields with their sort directions
4. Click "Create"

### Option 3: Using firebase.json (For CI/CD)
Add these index definitions to your `firestore.indexes.json` file:

```json
{
  "indexes": [
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "faqs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "senderId", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## Error Handling

The app includes proper error handling for missing indexes:

### Notifications Screen
- Shows error icon with message
- Suggests creating the required index
- User-friendly error display

### FAQ Screen
- Shows error with helpful message
- Mentions index creation requirement
- Graceful degradation

### Chat Service
- Logs errors to console
- Provides user-friendly error messages
- Allows retry functionality

## Notes

1. **Client-Side Filtering:** The chat list uses client-side sorting instead of orderBy to avoid requiring a composite index. This is acceptable for smaller chat lists.

2. **Single-Field Indexes:** Firebase automatically creates single-field indexes, so queries with only one where clause or orderBy don't need manual index creation.

3. **Index Build Time:** After creating an index, it may take a few minutes to build. The app will continue to show errors until the index is ready.

4. **Testing:** Always test queries in development before deploying to production to ensure all required indexes are created.

## Troubleshooting

### "The query requires an index" Error
1. Look at the error message for the exact fields needed
2. Click the link in the error (if in browser console)
3. Or manually create the index as described above

### Index Already Exists
- Firebase may have auto-created some indexes
- Check the Indexes tab in Firebase Console
- Delete duplicate indexes if needed

### Query Still Fails After Index Creation
- Wait 2-5 minutes for index to fully build
- Check index status in Firebase Console
- Verify field names match exactly (case-sensitive)
