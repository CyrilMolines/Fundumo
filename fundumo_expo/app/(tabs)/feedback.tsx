import { FlashList } from '@shopify/flash-list';
import { formatDistanceToNow } from 'date-fns';
import { Stack } from 'expo-router';
import React, { useMemo, useState } from 'react';
import { Alert, Pressable, StyleSheet, TextInput, View } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { useFeedbackStore } from '@/src/state/feedbackStore';
import type { FeedbackEntry } from '@/src/types';

const FeedbackCard = ({
  entry,
  onResolve,
  onDelete,
}: {
  entry: FeedbackEntry;
  onResolve: (id: string) => void;
  onDelete: (id: string) => void;
}) => {
  const createdAgo = formatDistanceToNow(new Date(entry.createdAt), { addSuffix: true });
  return (
    <ThemedView style={styles.card}>
      <View style={styles.cardHeader}>
        <View>
          <ThemedText type="subtitle">{entry.topic}</ThemedText>
          <ThemedText style={styles.cardMeta}>{createdAgo}</ThemedText>
        </View>
        <View style={styles.badgeRow}>
          <View style={[styles.statusBadge, entry.resolvedAt ? styles.resolved : styles.active]}>
            <ThemedText style={styles.badgeText}>
              {entry.resolvedAt ? 'Resolved' : 'Awaiting'}
            </ThemedText>
          </View>
        </View>
      </View>
      <ThemedText style={styles.cardDescription}>{entry.message}</ThemedText>
      <View style={styles.codeRow}>
        <ThemedText style={styles.cardMeta}>{entry.anonymousCode}</ThemedText>
        {entry.mood && <ThemedText style={styles.cardMeta}>Mood: {entry.mood}</ThemedText>}
      </View>
      <View style={styles.actionsRow}>
        {!entry.resolvedAt && (
          <Pressable
            style={styles.secondaryButton}
            onPress={() => onResolve(entry.id)}
            accessibilityLabel="Resolve feedback">
            <ThemedText style={styles.secondaryButtonText}>Mark resolved</ThemedText>
          </Pressable>
        )}
        <Pressable
          style={styles.destructiveButton}
          onPress={() =>
            Alert.alert('Delete feedback?', 'This action cannot be undone.', [
              { text: 'Cancel', style: 'cancel' },
              { text: 'Delete', style: 'destructive', onPress: () => onDelete(entry.id) },
            ])
          }>
          <ThemedText style={styles.destructiveButtonText}>Delete</ThemedText>
        </Pressable>
      </View>
    </ThemedView>
  );
};

export default function FeedbackScreen() {
  const colorScheme = useColorScheme();
  const palette = Colors[colorScheme ?? 'light'];
  const { entries, addFeedback, resolveFeedback, deleteFeedback, unresolvedCount } =
    useFeedbackStore();

  const [topic, setTopic] = useState('');
  const [message, setMessage] = useState('');
  const [mood, setMood] = useState('');

  const orderedEntries = useMemo(
    () =>
      [...entries].sort(
        (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
      ),
    [entries],
  );

  const handleSubmit = () => {
    try {
      const entry = addFeedback({ topic, message, mood });
      setTopic('');
      setMessage('');
      setMood('');
      Alert.alert('Feedback stored anonymously', `Track it later with code ${entry.anonymousCode}`);
    } catch (error) {
      Alert.alert('Unable to submit feedback', String(error));
    }
  };

  return (
    <ThemedView style={styles.screen}>
      <Stack.Screen options={{ title: 'Anonymous Feedback' }} />
      <FlashList
        contentContainerStyle={styles.listContent}
        data={orderedEntries}
        estimatedItemSize={240}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <FeedbackCard entry={item} onResolve={resolveFeedback} onDelete={deleteFeedback} />
        )}
        ListHeaderComponent={
          <View style={styles.headerContent}>
            <View style={styles.metricsRow}>
              <View style={styles.metricCard}>
                <ThemedText type="title">{orderedEntries.length}</ThemedText>
                <ThemedText style={styles.cardMeta}>Total ideas</ThemedText>
              </View>
              <View style={styles.metricCard}>
                <ThemedText type="title">{unresolvedCount}</ThemedText>
                <ThemedText style={styles.cardMeta}>Needs response</ThemedText>
              </View>
            </View>
            <ThemedView style={styles.formCard}>
              <ThemedText type="title" style={styles.formTitle}>
                Share what’s on your mind
              </ThemedText>
              <Label text="Topic" />
              <TextInput
                placeholder="Feature request, team ritual, budget…"
                value={topic}
                onChangeText={setTopic}
                style={styles.input}
              />
              <Label text="Message" />
              <TextInput
                placeholder="Give as much context as you like."
                value={message}
                onChangeText={setMessage}
                multiline
                style={[styles.input, styles.multiline]}
              />
              <Label text="Mood (optional)" />
              <TextInput
                placeholder="energized, frustrated, curious…"
                value={mood}
                onChangeText={setMood}
                style={styles.input}
              />
              <Pressable
                style={[styles.primaryButton, { backgroundColor: palette.tint }]}
                onPress={handleSubmit}>
                <ThemedText style={styles.primaryButtonText}>Submit anonymously</ThemedText>
              </Pressable>
            </ThemedView>
          </View>
        }
        ListEmptyComponent={
          <ThemedText style={styles.emptyListText}>
            Your first piece of feedback will appear here.
          </ThemedText>
        }
      />
    </ThemedView>
  );
}

const Label = ({ text }: { text: string }) => (
  <ThemedText type="defaultSemiBold" style={styles.label}>
    {text}
  </ThemedText>
);

const styles = StyleSheet.create({
  screen: {
    flex: 1,
  },
  listContent: {
    padding: 20,
    gap: 16,
  },
  headerContent: {
    gap: 16,
  },
  metricsRow: {
    flexDirection: 'row',
    gap: 12,
  },
  metricCard: {
    flex: 1,
    padding: 16,
    borderRadius: 16,
    backgroundColor: '#f5f7ff',
  },
  formCard: {
    padding: 16,
    borderRadius: 16,
    gap: 10,
  },
  formTitle: {
    marginBottom: 8,
  },
  input: {
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#d0d5dd',
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 16,
  },
  multiline: {
    minHeight: 120,
    textAlignVertical: 'top',
  },
  label: {
    marginTop: 12,
    marginBottom: 4,
  },
  primaryButton: {
    paddingVertical: 14,
    borderRadius: 999,
    marginTop: 12,
  },
  primaryButtonText: {
    textAlign: 'center',
    color: '#fff',
    fontWeight: '600',
  },
  card: {
    padding: 16,
    borderRadius: 16,
    marginVertical: 8,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  badgeRow: {
    flexDirection: 'row',
    gap: 6,
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
  },
  active: {
    backgroundColor: '#fff3cd',
  },
  resolved: {
    backgroundColor: '#e3f9e5',
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '600',
  },
  cardMeta: {
    color: '#7a869a',
    marginTop: 4,
  },
  cardDescription: {
    marginTop: 12,
    lineHeight: 22,
  },
  codeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 12,
  },
  actionsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 16,
  },
  secondaryButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: '#d0d5dd',
  },
  secondaryButtonText: {
    textAlign: 'center',
    fontWeight: '600',
  },
  destructiveButton: {
    paddingVertical: 12,
    paddingHorizontal: 18,
    borderRadius: 999,
    backgroundColor: '#fee2e2',
  },
  destructiveButtonText: {
    color: '#b42318',
    fontWeight: '600',
  },
  emptyListText: {
    textAlign: 'center',
    color: '#7a869a',
    marginVertical: 20,
  },
});

