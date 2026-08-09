<script setup>
import { computed } from 'vue';
import BarChart from 'shared/components/charts/BarChart.vue';
const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

const labels = computed(() => ({
  title: 'Admin Dashboard',
  accounts: 'Accounts',
  users: 'Users',
  inboxes: 'Inboxes',
  conversations: 'Conversations',
  chartLabel: 'Conversations',
  ...(props.componentData.labels || {}),
}));

const prepareData = sourceData => {
  var chartLabels = [];
  var data = [];
  sourceData.forEach(item => {
    chartLabels.push(item[0]);
    data.push(item[1]);
  });
  return {
    labels: chartLabels,
    datasets: [
      {
        type: 'bar',
        backgroundColor: 'rgb(31, 147, 255)',
        yAxisID: 'y',
        label: labels.value.chartLabel,
        data: data,
      },
    ],
  };
};

const chartData = computed(() => {
  return prepareData(props.componentData.chartData);
});

const { accountsCount, usersCount, inboxesCount, conversationsCount } =
  props.componentData;
</script>

<template>
  <div class="w-full h-full">
    <header class="main-content__header" role="banner">
      <h1 id="page-title" class="main-content__page-title">
        {{ labels.title }}
      </h1>
    </header>

    <section class="main-content__body main-content__body--flush">
      <div class="report--list">
        <div class="report-card">
          <div class="metric">{{ accountsCount }}</div>
          <div>{{ labels.accounts }}</div>
        </div>
        <div class="report-card">
          <div class="metric">{{ usersCount }}</div>
          <div>{{ labels.users }}</div>
        </div>
        <div class="report-card">
          <div class="metric">{{ inboxesCount }}</div>
          <div>{{ labels.inboxes }}</div>
        </div>
        <div class="report-card">
          <div class="metric">{{ conversationsCount }}</div>
          <div>{{ labels.conversations }}</div>
        </div>
      </div>
    </section>
    <!-- eslint-disable vue/no-static-inline-styles -->
    <BarChart
      class="p-8 w-full"
      :collection="chartData"
      style="max-height: 500px"
    />
  </div>
</template>
