import { format, formatDistanceToNow } from 'date-fns';
import { Link } from 'expo-router';
import React, { useMemo } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { useEventSummaryStore } from '@/src/state/eventSummaryStore';
import { useFeedbackStore } from '@/src/state/feedbackStore';
import { useMemoryLaneStore } from '@/src/state/memoryLaneStore';

export default function HomeScreen() {
  const colorScheme = useColorScheme();
  const palette = Colors[colorScheme ?? 'light'];
  const { summaries, tagCloud } = useEventSummaryStore();
  const { resurfaced } = useMemoryLaneStore();
  const { unresolvedCount, entries: feedbackEntries } = useFeedbackStore();

  const topHighlights = useMemo(() => {
    return summaries
      .flatMap((summary) =>
        summary.highlights.map((highlight) => ({
          ...highlight,
          summaryTitle: summary.title,
          createdAt: summary.createdAt,
        })),
      )
      .slice(0, 10);
  }, [summaries]);

  const topTags = useMemo(
    () =>
      Object.entries(tagCloud)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 4),
    [tagCloud],
  );

  return (
    <ThemedView style={styles.screen}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.hero}>
          <ThemedText type="title">Fundumo Ops Center</ThemedText>
          <ThemedText style={styles.subtitle}>
            Track recaps, memories, and team signals from one place.
          </ThemedText>
        </View>
        <View style={styles.metricsGrid}>
          <Link href="/(tabs)/event-summary" asChild>
            <Pressable style={[styles.metricCard, { borderColor: palette.tint }]}>
              <ThemedText type="title">{summaries.length}</ThemedText>
              <ThemedText style={styles.metricLabel}>Event recaps</ThemedText>
            </Pressable>
          </Link>
          <Link href="/(tabs)/memory-lane" asChild>
            <Pressable style={[styles.metricCard, { borderColor: '#a66cff' }]}>
              <ThemedText type="title">{resurfaced.length}</ThemedText>
              <ThemedText style={styles.metricLabel}>Resurfacing today</ThemedText>
            </Pressable>
          </Link>
          <Link href="/(tabs)/feedback" asChild>
            <Pressable style={[styles.metricCard, { borderColor: '#ff9f68' }]}>
              <ThemedText type="title">{unresolvedCount}</ThemedText>
              <ThemedText style={styles.metricLabel}>Unresolved feedback</ThemedText>
            </Pressable>
          </Link>
        </View>
        <View>
          <View style={styles.sectionHeader}>
            <ThemedText type="subtitle">Recent highlights</ThemedText>
            <Link href="/(tabs)/event-summary">
              <ThemedText style={styles.link}>View all</ThemedText>
            </Link>
          </View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {topHighlights.map((item) => (
              <View key={item.id} style={styles.highlightCard}>
                <ThemedText type="defaultSemiBold">{item.text}</ThemedText>
                <ThemedText style={styles.highlightMeta}>from {item.summaryTitle}</ThemedText>
              </View>
            ))}
            {!topHighlights.length && (
              <ThemedText style={styles.emptyText}>
                Add an event summary to populate this section.
              </ThemedText>
            )}
          </ScrollView>
        </View>
        <View>
          <View style={styles.sectionHeader}>
            <ThemedText type="subtitle">Tag momentum</ThemedText>
          </View>
          <View style={styles.tagGrid}>
            {topTags.map(([tag, count]) => (
              <View key={tag} style={styles.tagBadge}>
                <ThemedText style={styles.tagText}>{tag}</ThemedText>
                <ThemedText style={styles.tagCount}>×{count}</ThemedText>
              </View>
            ))}
            {!topTags.length && (
              <ThemedText style={styles.emptyText}>
                Your top tags will appear after the first recap.
              </ThemedText>
            )}
          </View>
        </View>
        <View>
          <View style={styles.sectionHeader}>
            <ThemedText type="subtitle">Latest anonymous signals</ThemedText>
            <Link href="/(tabs)/feedback">
              <ThemedText style={styles.link}>Respond</ThemedText>
            </Link>
          </View>
          {feedbackEntries.slice(0, 5).map((item) => (
            <View key={item.id} style={styles.signalCard}>
              <ThemedText type="defaultSemiBold">{item.topic}</ThemedText>
              <ThemedText style={styles.signalMeta}>
                {formatDistanceToNow(new Date(item.createdAt), { addSuffix: true })}
              </ThemedText>
              <ThemedText numberOfLines={2}>{item.message}</ThemedText>
              <ThemedText style={styles.codeText}>{item.anonymousCode}</ThemedText>
            </View>
          ))}
          {!feedbackEntries.length && (
            <ThemedText style={styles.emptyText}>No anonymous feedback yet.</ThemedText>
          )}
        </View>
        <View>
          <View style={styles.sectionHeader}>
            <ThemedText type="subtitle">Memory resurfacing</ThemedText>
            <Link href="/(tabs)/memory-lane">
              <ThemedText style={styles.link}>Open Memory Lane</ThemedText>
            </Link>
          </View>
          <View style={styles.memoryGrid}>
            {resurfaced.map((memory) => (
              <View key={memory.id} style={styles.memoryCard}>
                <ThemedText type="defaultSemiBold">{memory.title}</ThemedText>
                <ThemedText style={styles.memoryDate}>
                  {format(new Date(memory.capturedOn), 'MMM d, yyyy')}
                </ThemedText>
              </View>
            ))}
            {!resurfaced.length && (
              <ThemedText style={styles.emptyText}>
                Add at least one memory to activate resurfacing.
              </ThemedText>
            )}
          </View>
        </View>
      </ScrollView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
    gap: 24,
  },
  hero: {
    gap: 8,
  },
  subtitle: {
    color: '#6b7280',
  },
  metricsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  metricCard: {
    flexBasis: '30%',
    borderRadius: 16,
    borderWidth: 1,
    padding: 16,
  },
  metricLabel: {
    color: '#6b7280',
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  link: {
    color: '#2563eb',
    fontWeight: '600',
  },
  highlightCard: {
    borderRadius: 16,
    padding: 16,
    marginRight: 12,
    backgroundColor: '#f5f7ff',
    width: 220,
  },
  highlightMeta: {
    marginTop: 6,
    color: '#6b7280',
  },
  tagGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  tagBadge: {
    flexDirection: 'row',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
    backgroundColor: '#f3f4f6',
  },
  tagText: {
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    fontWeight: '600',
  },
  tagCount: {
    color: '#4b5563',
  },
  signalCard: {
    padding: 16,
    borderRadius: 16,
    backgroundColor: '#fff7f0',
    marginBottom: 12,
  },
  signalMeta: {
    color: '#6b7280',
    marginVertical: 4,
  },
  codeText: {
    marginTop: 6,
    fontWeight: '600',
  },
  memoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  memoryCard: {
    borderRadius: 16,
    padding: 16,
    backgroundColor: '#eef2ff',
    flexBasis: '48%',
  },
  memoryDate: {
    color: '#6b7280',
    marginTop: 4,
  },
  emptyText: {
    color: '#9ca3af',
  },
});
