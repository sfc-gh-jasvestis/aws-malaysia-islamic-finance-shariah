'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';
import { GeoMap } from '@/components/GeoMap';
import { ArchitectureDiagram } from '@/components/ArchitectureDiagram';

interface DemoNarrative {
  title: string;
  duration: string;
  thesis: string;
  tabs: any[];
}

export default function HomePage() {
  const [narrative, setNarrative] = useState<DemoNarrative | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/demo_narrative.json')
      .then((r) => r.json())
      .then(setNarrative)
      .catch(() => {});
    fetch('/api/data')
      .then((r) => r.json())
      .then(setData)
      .catch(() => {});
  }, []);

  const title = narrative?.title || 'SEA AWS Demo';

  const executiveCockpit = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="Shariah AUM" value="RM 847B" status="neutral" />
        <KPICard title="SAC Resolutions" value="24" status="neutral" />
        <KPICard title="Products Screened" value="1,247" status="neutral" />
        <KPICard title="Compliance Rate" value="100%" status="neutral" />
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="lg:col-span-1">
          <GeoMap
            country="malaysia"
            markers={[{"label": "Kuala Lumpur", "value": "Islamic finance hub", "color": "blue", "size": "lg"}, {"label": "Penang", "value": "Regional branch", "color": "green", "size": "md"}, {"label": "Johor Bahru", "value": "Southern ops", "color": "green", "size": "md"}, {"label": "Kota Kinabalu", "value": "E.Malaysia branch", "color": "green", "size": "sm"}]}
            routes={[]}
            title="Geographic Overview"
            height={400}
          />
        </div>
        <div className="lg:col-span-1 grid grid-cols-1 gap-4">
      <div className="grid grid-cols-1 gap-4 grid-cols-1">
        <Chart data={data?.timeseries || [{ period: 'Loading', value: 0 }]} type="line" xKey="period" yKeys={[{ key: 'value', name: 'RM B' }]} title="Islamic Finance Growth (Annual)" />
        <Chart data={data?.categories || [{ category: 'Loading', count: 0 }]} type="bar" xKey="category" yKeys={[{ key: 'count', name: 'RM B' }]} title="AUM by Product Type" />
      </div>
        </div>
      </div>
      <DataTable columns={[
          { key: 'id', header: '#' },
          { key: 'name', header: 'Product' },
          { key: 'status', header: 'SAC Status' },
          { key: 'value', header: 'AUM (RM B)' },
      ]} data={data?.entities || []} title="Shariah Compliance Dashboard" />
    </div>
  );

  const domainTab1 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="Equities Screened" value="847" />
        <KPICard title="Sukuk Reviewed" value="124" />
        <KPICard title="New Rulings" value="4" />
      </div>
      <Chart data={data?.detail || [{ x: 'Loading', y: 0 }]} type="area" xKey="x" yKeys={[{ key: 'y', name: 'Securities' }]} title="Shariah-Compliant Universe" height={400} />
    </div>
  );

  const domainTab2 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart data={data?.breakdown || [{ label: 'A', value: 30 }, { label: 'B', value: 70 }]} type="pie" xKey="label" yKeys={[{ key: 'value', name: 'Status' }]} title="Resolution Implementation" />
        <ActionMemo persona={{ name: 'Prof. Dr. Mohamad Akram', role: 'SAC Chairman' }} context={{}} onGenerate={async () => ({ subject: 'Action Required', body: 'AI-generated recommendation based on current data patterns.', urgency: 'HIGH', actions: ['Review crypto-asset Shariah classification', 'Update ESG-Islamic hybrid screening', 'Issue guidance on digital sukuk tokenization'] })} />
      </div>
    </div>
  );

  const askAiTab = (
    <div className="h-[600px]">
      <AskAI title="Ask AI" mode="sql" sampleQuestions={['How many securities passed latest Shariah screening?', 'Show Islamic vs conventional AUM growth', 'What SAC resolutions are pending?']} onSubmit={async (question, mode) => ({ answer: `[Demo Mode] Response to: "${question}" (${mode} mode). Connect to Snowflake for live data.`, sql: mode === 'sql' ? 'SELECT * FROM CURATED.SUMMARY LIMIT 10;' : undefined })} />
    </div>
  );

  const architectureTab = (
    <ArchitectureDiagram
      snowflakeFeatures={['Dynamic Tables (5-min refresh)', 'ML Functions (Forecast + Anomaly)', 'Cortex Search + Agent', 'Semantic View + Intelligence', 'Alerts + Notifications']}
      awsServices={[{ name: 'Amazon S3', role: 'Strategy Docs' }, { name: 'Amazon S3 + Kinesis', role: 'Integration' }, { name: 'Amazon SNS', role: 'Integration' }, { name: 'Amazon QuickSight + Q', role: 'Integration' }]}
    />
  );

  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '📊', content: executiveCockpit },
    { id: 'domain-1', label: 'Screening', icon: '📈', content: domainTab1 },
    { id: 'domain-2', label: 'Governance', icon: '⚡', content: domainTab2 },
    { id: 'ask-ai', label: 'Ask AI', icon: '🤖', content: askAiTab },
    { id: 'architecture', label: 'Architecture & Data', icon: '🏗️', content: architectureTab },
  ];

  return <AppLayout title={title} tabs={tabs} narrative={narrative} />;
}
